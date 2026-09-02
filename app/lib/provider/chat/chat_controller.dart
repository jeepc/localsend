import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/model/persistence/pending_friend_request.dart';
import 'package:localsend_app/provider/chat/chat_provider.dart';
import 'package:localsend_app/provider/chat/friends_provider.dart';
import 'package:localsend_app/provider/chat/pending_friend_requests_provider.dart';
import 'package:localsend_app/provider/chat/selected_friend_provider.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/http_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/chat_envelope.dart';
import 'package:localsend_app/util/friends.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/model/dto/file_dto.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:localsend_isolates/rust/api/cancel.dart' as rust_cancel;
import 'package:localsend_isolates/rust/api/http.dart' as rust_http;
import 'package:localsend_isolates/rust/api/model.dart' as rust_model;
import 'package:localsend_isolates/util/rust.dart';
import 'package:localsend_isolates/util/sleep.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _logger = Logger('Chat');

/// Bounds a chat request, which nobody has to accept by hand.
///
/// Generous, because the answer decides what the user is told: a peer that is
/// merely slow — a phone whose app the system is thawing, a device answering
/// while a transfer saturates the link — stores and shows the message anyway,
/// so giving up early is what produces a message that is marked undelivered on
/// one side and read on the other.
const _chatTimeoutMs = 20000;

/// Backoff before retrying a message that did not reach the peer.
///
/// The Rust server allows only one upload session at a time, so a chat message
/// sent while a file transfer runs gets a 409. That is transient by nature, and
/// so is a timeout or a broken connection. Retrying is safe: the receiver keys
/// messages, friend requests and answers by their id and ignores the ones it
/// already has.
const _retryDelays = [Duration(seconds: 2), Duration(seconds: 5)];

/// Sends a chat text message to a friend, optimistically showing it right away.
class SendChatTextAction extends AsyncGlobalAction {
  final String fingerprint;
  final String text;

  SendChatTextAction({required this.fingerprint, required this.text});

  @override
  Future<void> reduce() async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final message = ChatMessage.outgoingText(peerFingerprint: fingerprint, text: trimmed);
    await ref.redux(chatProvider).dispatchAsync(AppendMessageAction(message));
    await ref.global.dispatchAsync(DeliverChatMessageAction(message));
  }
}

/// Retries a message that failed to reach the peer.
class ResendChatMessageAction extends AsyncGlobalAction {
  final ChatMessage message;

  ResendChatMessageAction(this.message);

  @override
  Future<void> reduce() async {
    if (message.type != ChatMessageType.text || message.text == null) {
      return;
    }
    final retrying = message.copyWith(status: ChatMessageStatus.sending);
    await ref.redux(chatProvider).dispatchAsync(UpdateMessageAction(retrying));
    await ref.global.dispatchAsync(DeliverChatMessageAction(retrying));
  }
}

/// Puts a text message on the wire and records whether it arrived.
class DeliverChatMessageAction extends AsyncGlobalAction {
  final ChatMessage message;

  DeliverChatMessageAction(this.message);

  @override
  Future<void> reduce() async {
    final target = ref.resolveChatTarget(message.peerFingerprint);
    if (target == null) {
      await ref.redux(chatProvider).dispatchAsync(UpdateMessageAction(message.copyWith(status: ChatMessageStatus.failed)));
      return;
    }

    final envelope = ChatTextEnvelope(
      messageId: message.id,
      timestamp: message.timestamp,
      text: message.text ?? '',
    );

    final delivered = await ref.sendChatEnvelopeWithRetry(target, envelope);

    await ref
        .redux(chatProvider)
        .dispatchAsync(
          UpdateMessageAction(message.copyWith(status: delivered ? ChatMessageStatus.sent : ChatMessageStatus.failed)),
        );
  }
}

/// Asks a device to become a friend. Returns true if the request was delivered.
class SendFriendRequestAction extends AsyncGlobalActionWithResult<bool> {
  final Device device;

  /// Group the friend should land in once accepted, resolved by the caller
  /// while the user is present to name an unknown network.
  final String? networkId;

  SendFriendRequestAction(this.device, {required this.networkId});

  @override
  Future<bool> reduce() async {
    final requestId = _uuid.v4();
    final originDevice = ref.read(deviceFullInfoProvider);
    final envelope = FriendRequestEnvelope(requestId: requestId, alias: originDevice.alias);

    // Record the request *before* putting it on the wire. The peer is released
    // as soon as it answers 204 and can reply at any moment after that, so a
    // reply that overtakes this (async, disk-backed) write would be dropped as
    // belonging to an unknown request.
    await ref
        .redux(pendingFriendRequestsProvider)
        .dispatchAsync(
          AddPendingFriendRequestAction(
            PendingFriendRequest(
              requestId: requestId,
              fingerprint: device.fingerprint,
              alias: device.alias,
              ip: device.ip,
              port: device.port,
              networkId: networkId,
              createdAt: DateTime.now().toUtc(),
            ),
          ),
        );

    _logger.info('Sending friend request $requestId to ${device.alias} (${device.ip}:${device.port}).');
    final delivered = await ref.sendChatEnvelopeWithRetry(device, envelope);
    if (!delivered) {
      _logger.warning('Friend request $requestId to ${device.alias} could not be delivered.');
      await ref.redux(pendingFriendRequestsProvider).dispatchAsync(RemovePendingFriendRequestAction(requestId: requestId));
      return false;
    }
    return true;
  }
}

/// Answers an incoming friend request and, when accepted, stores the friend.
///
/// Returns whether the answer reached the requester. A lost answer leaves the
/// two sides disagreeing about the friendship, so the caller reports it.
class RespondToFriendRequestAction extends AsyncGlobalActionWithResult<bool> {
  final String requestId;
  final bool accepted;
  final Device requester;

  /// Group the new friend lands in: the network *this* device is on, which is
  /// what "公司"/"家里" means from the answering side.
  final String? networkId;

  RespondToFriendRequestAction({
    required this.requestId,
    required this.accepted,
    required this.requester,
    required this.networkId,
  });

  @override
  Future<bool> reduce() async {
    if (accepted) {
      await ref
          .redux(friendsProvider)
          .dispatchAsync(
            AddFriendAction(
              Friend.fromValues(
                fingerprint: requester.fingerprint,
                alias: requester.alias,
                ip: requester.ip,
                port: requester.port,
                networkId: networkId,
              ),
            ),
          );
    }

    // Reply to the device as it is known to discovery when possible: the
    // address in the request payload is the only callback path in the protocol
    // and nothing else exercises it, so a stale port there would strand the
    // handshake. Fall back to the payload for a peer we have not discovered.
    final target = ref.resolveChatTarget(requester.fingerprint) ?? requester;
    final originDevice = ref.read(deviceFullInfoProvider);

    _logger.info('Answering friend request $requestId (accepted: $accepted) to ${target.alias} (${target.ip}:${target.port}).');
    final delivered = await ref.sendChatEnvelopeWithRetry(
      target,
      FriendResponseEnvelope(requestId: requestId, accepted: accepted, alias: originDevice.alias),
    );
    if (!delivered) {
      _logger.warning('Could not deliver the answer to friend request $requestId; the requester will not see the friendship.');
    }
    return delivered;
  }
}

/// Handles the peer's answer to a friend request we sent earlier.
class HandleFriendResponseAction extends AsyncGlobalAction {
  final FriendResponseEnvelope envelope;
  final Device responder;

  HandleFriendResponseAction({required this.envelope, required this.responder});

  @override
  Future<void> reduce() async {
    final requests = ref.read(pendingFriendRequestsProvider);

    // Match on the request id, but fall back to the outstanding request for
    // this peer: a user who retried has a newer id locally while the peer is
    // answering the one it was asked. Either way an answer is only accepted
    // when we really do have a request pending for that exact fingerprint,
    // so nobody can add themselves.
    final byId = requests.findByRequestId(envelope.requestId);
    final pending = byId ?? requests.findByFingerprint(responder.fingerprint);
    if (pending == null) {
      _logger.warning('Ignoring a friend response for an unknown request (${envelope.requestId}) from ${responder.alias}.');
      return;
    }
    // Certificate fingerprints are uppercase hex, but a peer discovered over
    // multicast may report a differently cased one, so compare case-insensitively.
    if (pending.fingerprint.toUpperCase() != responder.fingerprint.toUpperCase()) {
      _logger.warning('Ignoring a friend response whose sender does not match the request target.');
      return;
    }

    await ref.redux(pendingFriendRequestsProvider).dispatchAsync(RemovePendingFriendRequestAction(requestId: pending.requestId));

    if (!envelope.accepted) {
      // Without this the request just disappears and the add button silently
      // comes back, leaving the user guessing.
      _logger.info('${responder.alias} declined the friend request.');
      final context = Routerino.context;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.dialogs.friendRequest.declinedByPeer(alias: pending.alias))),
        );
      }
      return;
    }
    _logger.info('${responder.alias} accepted the friend request; adding to the friend list.');

    await ref
        .redux(friendsProvider)
        .dispatchAsync(
          AddFriendAction(
            Friend.fromValues(
              fingerprint: responder.fingerprint,
              alias: envelope.alias.isNotEmpty ? envelope.alias : responder.alias,
              ip: responder.ip,
              port: responder.port,
              networkId: pending.networkId,
            ),
          ),
        );
  }
}

/// Removes a friend locally and tells them, so the friendship disappears on
/// both sides.
///
/// The notification is best effort: an unreachable peer must not stop the user
/// from removing someone from their own list.
class UnfriendAction extends AsyncGlobalAction {
  final String fingerprint;

  UnfriendAction(this.fingerprint);

  @override
  Future<void> reduce() async {
    final target = ref.resolveChatTarget(fingerprint);

    await ref.redux(friendsProvider).dispatchAsync(RemoveFriendAction(fingerprint: fingerprint));

    if (target == null) {
      _logger.info('Removed a friend that is not reachable; the peer keeps the friendship until it hears from us.');
      return;
    }
    final delivered = await ref.sendChatEnvelope(target, UnfriendEnvelope(id: _uuid.v4()));
    if (delivered != ChatSendResult.delivered) {
      _logger.info('Could not tell ${target.alias} about the removal; the friendship lingers on their side.');
    }
  }
}

/// Applies an incoming removal: the peer dropped us, so we drop them.
class HandleUnfriendAction extends AsyncGlobalAction {
  final String fingerprint;

  HandleUnfriendAction(this.fingerprint);

  @override
  Future<void> reduce() async {
    if (!ref.read(friendsProvider).containsFingerprint(fingerprint)) {
      return;
    }
    _logger.info('Peer $fingerprint removed the friendship; removing it here as well.');
    await ref.redux(friendsProvider).dispatchAsync(RemoveFriendAction(fingerprint: fingerprint));
  }
}

/// Records files that were transferred to or from a friend as one chat message.
///
/// File messages carry no protocol marker: any file exchanged with a friend
/// belongs to that conversation, which is also what the user expects.
class RecordFilesMessageAction extends AsyncGlobalAction {
  final String fingerprint;
  final bool outgoing;

  /// The files of a single transfer, which become a single message.
  final List<ChatFile> files;

  /// Defaults to sent/received. Pass [ChatMessageStatus.failed] to leave a
  /// record of files that never made it, so the user can retry them.
  final ChatMessageStatus? status;

  /// Identifies the transfer. Files reported one after another are folded into
  /// the message with this id, and the caller can move that message to another
  /// status later. A new message is appended when it is null.
  final String? messageId;

  RecordFilesMessageAction({
    required this.fingerprint,
    required this.outgoing,
    required this.files,
    this.status,
    this.messageId,
  });

  @override
  Future<void> reduce() async {
    if (!ref.read(friendsProvider).containsFingerprint(fingerprint)) {
      return;
    }
    await ref
        .redux(chatProvider)
        .dispatchAsync(
          AppendFilesAction(
            fingerprint: fingerprint,
            outgoing: outgoing,
            files: files,
            status: status,
            messageId: messageId,
          ),
        );
  }
}

enum ChatSendResult {
  delivered,

  /// The peer is mid-transfer. The single-session invariant makes this
  /// transient, so it is worth retrying.
  busy,

  /// The request did not produce an answer: it timed out, the connection broke
  /// or the peer was not reachable at that moment. The peer may well have
  /// received it, which is exactly why this is retried instead of reported —
  /// the receiver drops the duplicate.
  noAnswer,

  permanentFailure,
}

extension ChatRefExt on Ref {
  /// Opens a friend's conversation.
  ///
  /// Conversations are read from disk lazily, so selecting a friend is only
  /// half of it — the history has to be requested as well.
  void openConversation(String fingerprint) {
    notifier(selectedFriendProvider).select(fingerprint);
    redux(chatProvider).dispatch(LoadConversationAction(fingerprint));
  }

  /// The best current address for a peer.
  ///
  /// Prefers a freshly discovered device over the address stored on the friend,
  /// which goes stale as soon as DHCP hands out a different lease.
  Device? resolveChatTarget(String fingerprint) {
    final discovered = read(nearbyDevicesProvider).allDevices[fingerprint];
    if (discovered != null && discovered.ip != null) {
      return discovered;
    }

    final friend = read(friendsProvider).findByFingerprint(fingerprint);
    if (friend?.lastIp == null) {
      return null;
    }
    return Device(
      signalingId: null,
      ip: friend!.lastIp,
      version: '2.1',
      port: friend.lastPort,
      // Encryption is a global setting and both sides have to agree on it, so
      // it describes the peer as well. Hardcoding https here made every send
      // over the stored address fail once the user turned encryption off — and
      // that address is only ever used when discovery already failed, which is
      // why it stayed hidden.
      https: read(settingsProvider).https,
      fingerprint: friend.fingerprint,
      alias: friend.alias,
      deviceModel: null,
      deviceType: DeviceType.desktop,
      download: false,
      channels: const [],
    );
  }

  /// Sends an envelope, retrying while the peer is busy or does not answer.
  ///
  /// A busy peer is transient by construction: the Rust server allows a single
  /// upload session at a time, so a chat payload sent during a file transfer is
  /// rejected until that transfer ends. A missing answer is transient too — the
  /// peer may have been thawing, or the answer was lost on the way back — and
  /// resending is harmless because the receiver ignores an envelope it already
  /// has.
  Future<bool> sendChatEnvelopeWithRetry(Device target, ChatEnvelope envelope) async {
    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      final result = await sendChatEnvelope(target, envelope);
      if (result == ChatSendResult.delivered) {
        return true;
      }
      if (result == ChatSendResult.permanentFailure || attempt == _retryDelays.length) {
        return false;
      }
      await sleepAsync(_retryDelays[attempt].inMilliseconds);
    }
    return false;
  }

  /// Sends one envelope as a single-text-file transfer.
  ///
  /// The peer auto-accepts it with an empty file map, which the server answers
  /// with 204, so no actual upload follows.
  Future<ChatSendResult> sendChatEnvelope(Device target, ChatEnvelope envelope) async {
    if (target.ip == null) {
      _logger.warning('Cannot send a chat envelope to ${target.alias}: no address known.');
      return ChatSendResult.permanentFailure;
    }

    final originDevice = read(deviceFullInfoProvider);
    final client = read(httpProvider).pinnedTo(target.fingerprint, timeoutMs: _chatTimeoutMs);
    final preview = envelope.preview;

    final fileDto = FileDto(
      id: _uuid.v4(),
      fileName: envelope.fileName,
      size: utf8.encode(preview).length,
      fileType: FileType.text,
      hash: null,
      preview: preview,
      metadata: null,
    );

    final payload = rust_model.PrepareUploadRequestDto(
      info: rust_model.RegisterDto(
        alias: originDevice.alias,
        version: originDevice.version,
        deviceModel: originDevice.deviceModel,
        deviceType: originDevice.deviceType.toRust(),
        token: originDevice.fingerprint,
        port: originDevice.port,
        protocol: originDevice.https ? rust_model.ProtocolType.https : rust_model.ProtocolType.http,
        hasWebInterface: originDevice.download,
      ),
      files: {fileDto.id: fileDto.toRust()},
    );

    final cancelToken = rust_cancel.createCancellationToken();
    try {
      final response = await client.prepareUpload(
        protocol: target.getProtocolType(),
        ip: target.ip!,
        port: target.port,
        payload: payload,
        // The peer is already verified during the TLS handshake by the
        // fingerprint the client is pinned to.
        publicKey: null,
        pin: null,
        cancelToken: cancelToken,
      );

      // 204 is the expected answer: the peer accepted nothing, which for a
      // message-only transfer means "read and close".
      if (response.statusCode == 204 || response.statusCode == 200) {
        return ChatSendResult.delivered;
      }
      _logger.warning('Unexpected status ${response.statusCode} while sending a chat envelope.');
      return ChatSendResult.permanentFailure;
    } on rust_http.RsHttpClientError_StatusCode catch (e) {
      if (e.status == 409 || e.status == 429) {
        return ChatSendResult.busy;
      }
      _logger.warning('Chat envelope rejected with status ${e.status}.');
      return ChatSendResult.permanentFailure;
    } on rust_http.RsHttpClientError_Reqwest catch (e) {
      // Timeout, refused connection, dropped connection: the peer never
      // answered, but it may have acted on the request all the same.
      _logger.warning('No answer from ${target.alias} for a chat envelope: ${e.field0}');
      return ChatSendResult.noAnswer;
    } on rust_http.RsHttpClientError_Io catch (e) {
      _logger.warning('No answer from ${target.alias} for a chat envelope: ${e.field0}');
      return ChatSendResult.noAnswer;
    } catch (e) {
      _logger.warning('Could not send a chat envelope to ${target.alias}', e);
      return ChatSendResult.permanentFailure;
    }
  }
}
