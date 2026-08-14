import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Maximum number of messages kept per conversation.
/// Older ones are dropped, mirroring the cap on the receive history.
const maxMessagesPerConversation = 500;

/// Conversations, keyed by the peer's certificate fingerprint.
///
/// Conversations are loaded lazily and stored one prefs key per peer, so
/// appending a message does not rewrite every other conversation. This holds
/// only state and persistence; the network side lives in `chat_controller.dart`.
final chatProvider = ReduxProvider<ChatService, Map<String, List<ChatMessage>>>((ref) {
  return ChatService(ref.read(persistenceProvider));
});

class ChatService extends ReduxNotifier<Map<String, List<ChatMessage>>> {
  final PersistenceService _persistence;

  ChatService(this._persistence);

  @override
  Map<String, List<ChatMessage>> init() => {};
}

/// Reads a conversation from disk into memory if it is not loaded yet.
class LoadConversationAction extends ReduxAction<ChatService, Map<String, List<ChatMessage>>> {
  final String fingerprint;

  LoadConversationAction(this.fingerprint);

  @override
  Map<String, List<ChatMessage>> reduce() {
    if (state.containsKey(fingerprint)) {
      return state;
    }
    return {
      ...state,
      fingerprint: List.unmodifiable(notifier._persistence.getChatMessages(fingerprint)),
    };
  }
}

/// Appends a message to a conversation and persists it.
class AppendMessageAction extends AsyncReduxAction<ChatService, Map<String, List<ChatMessage>>> {
  final ChatMessage message;

  AppendMessageAction(this.message);

  @override
  Future<Map<String, List<ChatMessage>>> reduce() async {
    final fingerprint = message.peerFingerprint;
    final existing = state[fingerprint] ?? notifier._persistence.getChatMessages(fingerprint);

    if (existing.any((e) => e.id == message.id)) {
      // The peer retried a message we already stored.
      await Future.microtask(() {});
      return state;
    }

    final trimmed = _capped([...existing, message]);

    await notifier._persistence.setChatMessages(fingerprint, trimmed);
    return {...state, fingerprint: List.unmodifiable(trimmed)};
  }
}

/// Records files of one transfer as a single message.
///
/// A transfer is one message, not one per file, so [messageId] identifies the
/// transfer: files that arrive one after another are folded into the message
/// that is already there. Without an id every call appends its own message.
class AppendFilesAction extends AsyncReduxAction<ChatService, Map<String, List<ChatMessage>>> {
  final String fingerprint;
  final bool outgoing;
  final List<ChatFile> files;
  final ChatMessageStatus? status;
  final String? messageId;

  AppendFilesAction({
    required this.fingerprint,
    required this.outgoing,
    required this.files,
    required this.status,
    required this.messageId,
  });

  @override
  Future<Map<String, List<ChatMessage>>> reduce() async {
    if (files.isEmpty) {
      await Future.microtask(() {});
      return state;
    }

    final existing = state[fingerprint] ?? notifier._persistence.getChatMessages(fingerprint);
    final index = messageId == null ? -1 : existing.indexWhere((e) => e.id == messageId);

    final List<ChatMessage> updated;
    if (index == -1) {
      updated = _capped([
        ...existing,
        ChatMessage.files(
          peerFingerprint: fingerprint,
          outgoing: outgoing,
          files: files,
          status: status,
          id: messageId,
        ),
      ]);
    } else {
      var message = existing[index];
      for (final file in files) {
        message = message.withFile(file);
      }
      if (status != null) {
        message = message.copyWith(status: status);
      }
      updated = <ChatMessage>[...existing]..replaceRange(index, index + 1, [message]);
    }

    await notifier._persistence.setChatMessages(fingerprint, updated);
    return {...state, fingerprint: List.unmodifiable(updated)};
  }
}

/// Replaces a message in place, e.g. to move it from sending to sent/failed.
class UpdateMessageAction extends AsyncReduxAction<ChatService, Map<String, List<ChatMessage>>> {
  final ChatMessage message;

  UpdateMessageAction(this.message);

  @override
  Future<Map<String, List<ChatMessage>>> reduce() async {
    final fingerprint = message.peerFingerprint;
    final existing = state[fingerprint];
    if (existing == null) {
      await Future.microtask(() {});
      return state;
    }
    final index = existing.indexWhere((e) => e.id == message.id);
    if (index == -1) {
      await Future.microtask(() {});
      return state;
    }

    final updated = <ChatMessage>[...existing]..replaceRange(index, index + 1, [message]);
    await notifier._persistence.setChatMessages(fingerprint, updated);
    return {...state, fingerprint: List.unmodifiable(updated)};
  }
}

/// Moves a single message to another status, addressing it by id.
///
/// Unlike [UpdateMessageAction] the caller does not need to hold the message,
/// and a conversation that is not in memory is read from disk first: a transfer
/// may well outlive the moment its conversation was open.
class UpdateMessageStatusAction extends AsyncReduxAction<ChatService, Map<String, List<ChatMessage>>> {
  final String fingerprint;
  final String messageId;
  final ChatMessageStatus status;

  UpdateMessageStatusAction({
    required this.fingerprint,
    required this.messageId,
    required this.status,
  });

  @override
  Future<Map<String, List<ChatMessage>>> reduce() async {
    final existing = state[fingerprint] ?? notifier._persistence.getChatMessages(fingerprint);
    final index = existing.indexWhere((e) => e.id == messageId);
    if (index == -1) {
      await Future.microtask(() {});
      return state;
    }

    final updated = <ChatMessage>[...existing]..replaceRange(index, index + 1, [existing[index].copyWith(status: status)]);
    await notifier._persistence.setChatMessages(fingerprint, updated);
    return {...state, fingerprint: List.unmodifiable(updated)};
  }
}

class ClearConversationAction extends AsyncReduxAction<ChatService, Map<String, List<ChatMessage>>> {
  final String fingerprint;

  ClearConversationAction(this.fingerprint);

  @override
  Future<Map<String, List<ChatMessage>>> reduce() async {
    await notifier._persistence.removeChatMessages(fingerprint);
    return {...state, fingerprint: const []};
  }
}

/// Drops the oldest messages of a conversation that grew past the cap.
List<ChatMessage> _capped(List<ChatMessage> messages) {
  return messages.length > maxMessagesPerConversation ? messages.sublist(messages.length - maxMessagesPerConversation) : messages;
}
