import 'dart:convert';

/// Marker prefix identifying a transfer that is really a chat control message.
///
/// Chat rides on the existing v2 text transfer: a single `FileType.text` file
/// whose content is carried in `FileDto.preview`. The receiver decides what a
/// transfer means by looking at the file name, which the protocol never
/// inspects.
///
/// For plain chat messages the preview stays the raw text, so a stock LocalSend
/// peer that knows nothing about this prefix still shows a perfectly normal
/// text message instead of an error or a blob of JSON.
const chatEnvelopePrefix = '_lschat_v1_';

const _typeMessage = 'msg';
const _typeFriendRequest = 'freq';
const _typeFriendResponse = 'fack';
const _typeUnfriend = 'unfr';

/// A chat payload decoded from a transfer's file name and preview.
sealed class ChatEnvelope {
  const ChatEnvelope();

  /// The file name to send this envelope under.
  String get fileName;

  /// The text to put into `FileDto.preview`.
  String get preview;

  /// Decodes an envelope, or returns null when [fileName] is not a chat
  /// transfer or the payload is malformed.
  static ChatEnvelope? tryParse(String fileName, String? preview) {
    if (!fileName.startsWith(chatEnvelopePrefix)) {
      return null;
    }
    var body = fileName.substring(chatEnvelopePrefix.length);
    if (body.endsWith('.txt')) {
      body = body.substring(0, body.length - '.txt'.length);
    }

    final separator = body.indexOf('_');
    if (separator == -1) {
      return null;
    }
    final type = body.substring(0, separator);
    final rest = body.substring(separator + 1);

    switch (type) {
      case _typeMessage:
        final idSeparator = rest.lastIndexOf('_');
        if (idSeparator == -1 || preview == null) {
          return null;
        }
        final messageId = rest.substring(0, idSeparator);
        final epochMs = int.tryParse(rest.substring(idSeparator + 1));
        if (messageId.isEmpty || epochMs == null) {
          return null;
        }
        return ChatTextEnvelope(
          messageId: messageId,
          timestamp: DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true),
          text: preview,
        );
      case _typeFriendRequest:
        final payload = _decodePayload(preview);
        if (payload == null) {
          return null;
        }
        return FriendRequestEnvelope(
          requestId: rest,
          alias: payload['alias'] as String? ?? '',
        );
      case _typeFriendResponse:
        final payload = _decodePayload(preview);
        if (payload == null) {
          return null;
        }
        return FriendResponseEnvelope(
          requestId: rest,
          accepted: payload['accepted'] == true,
          alias: payload['alias'] as String? ?? '',
        );
      case _typeUnfriend:
        if (_decodePayload(preview) == null) {
          return null;
        }
        return UnfriendEnvelope(id: rest);
      default:
        return null;
    }
  }
}

/// A chat text message. The preview carries the message verbatim.
class ChatTextEnvelope extends ChatEnvelope {
  final String messageId;
  final DateTime timestamp;
  final String text;

  const ChatTextEnvelope({
    required this.messageId,
    required this.timestamp,
    required this.text,
  });

  @override
  String get fileName => '$chatEnvelopePrefix${_typeMessage}_${messageId}_${timestamp.toUtc().millisecondsSinceEpoch}.txt';

  @override
  String get preview => text;
}

/// "I would like to add you as a friend."
class FriendRequestEnvelope extends ChatEnvelope {
  final String requestId;
  final String alias;

  const FriendRequestEnvelope({
    required this.requestId,
    required this.alias,
  });

  @override
  String get fileName => '$chatEnvelopePrefix${_typeFriendRequest}_$requestId.txt';

  @override
  String get preview => jsonEncode({'v': 1, 'type': 'friendRequest', 'alias': alias});
}

/// The answer to a [FriendRequestEnvelope].
class FriendResponseEnvelope extends ChatEnvelope {
  final String requestId;
  final bool accepted;
  final String alias;

  const FriendResponseEnvelope({
    required this.requestId,
    required this.accepted,
    required this.alias,
  });

  @override
  String get fileName => '$chatEnvelopePrefix${_typeFriendResponse}_$requestId.txt';

  @override
  String get preview => jsonEncode({'v': 1, 'type': 'friendAccept', 'accepted': accepted, 'alias': alias});
}

/// "I removed you from my friend list."
///
/// A friendship is mutual, so dropping it on one side has to drop it on the
/// other; otherwise the peer keeps a friend that no longer exists and the add
/// button stays hidden there forever.
class UnfriendEnvelope extends ChatEnvelope {
  final String id;

  const UnfriendEnvelope({required this.id});

  @override
  String get fileName => '$chatEnvelopePrefix${_typeUnfriend}_$id.txt';

  @override
  String get preview => jsonEncode({'v': 1, 'type': 'unfriend'});
}

Map<String, dynamic>? _decodePayload(String? preview) {
  if (preview == null) {
    return null;
  }
  try {
    final decoded = jsonDecode(preview);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
