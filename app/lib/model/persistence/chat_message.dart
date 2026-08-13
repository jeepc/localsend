import 'package:dart_mappable/dart_mappable.dart';
import 'package:uuid/uuid.dart';

part 'chat_message.mapper.dart';

const _uuid = Uuid();

@MappableEnum(defaultValue: ChatMessageType.text)
enum ChatMessageType {
  text,
  file,
  image,
}

@MappableEnum(defaultValue: ChatMessageStatus.sent)
enum ChatMessageStatus {
  sending,
  sent,

  /// Could not be delivered. The peer was offline, or the Rust server rejected
  /// it with 409 because a file transfer was occupying the single session slot.
  failed,

  received,
}

/// One entry of a conversation with a [Friend].
///
/// Conversations are keyed by the peer's certificate fingerprint and stored one
/// prefs key per peer, so appending a message does not rewrite every other
/// conversation.
@MappableClass()
class ChatMessage with ChatMessageMappable {
  final String id;
  final String peerFingerprint;

  /// True when this device sent the message.
  final bool outgoing;

  final ChatMessageType type;

  /// The message body for [ChatMessageType.text].
  final String? text;

  /// The original file name for file and image messages.
  final String? fileName;

  final int? fileSize;

  /// Where the file landed on this device, if it is still known.
  final String? filePath;

  final DateTime timestamp;
  final ChatMessageStatus status;

  const ChatMessage({
    required this.id,
    required this.peerFingerprint,
    required this.outgoing,
    required this.type,
    required this.text,
    required this.fileName,
    required this.fileSize,
    required this.filePath,
    required this.timestamp,
    required this.status,
  });

  factory ChatMessage.outgoingText({
    required String peerFingerprint,
    required String text,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? _uuid.v4(),
      peerFingerprint: peerFingerprint,
      outgoing: true,
      type: ChatMessageType.text,
      text: text,
      fileName: null,
      fileSize: null,
      filePath: null,
      timestamp: DateTime.now().toUtc(),
      status: ChatMessageStatus.sending,
    );
  }

  factory ChatMessage.incomingText({
    required String peerFingerprint,
    required String text,
    required String id,
    required DateTime timestamp,
  }) {
    return ChatMessage(
      id: id,
      peerFingerprint: peerFingerprint,
      outgoing: false,
      type: ChatMessageType.text,
      text: text,
      fileName: null,
      fileSize: null,
      filePath: null,
      timestamp: timestamp,
      status: ChatMessageStatus.received,
    );
  }

  factory ChatMessage.file({
    required String peerFingerprint,
    required bool outgoing,
    required String fileName,
    required int fileSize,
    required String? filePath,
    required bool isImage,
    ChatMessageStatus? status,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? _uuid.v4(),
      peerFingerprint: peerFingerprint,
      outgoing: outgoing,
      type: isImage ? ChatMessageType.image : ChatMessageType.file,
      text: null,
      fileName: fileName,
      fileSize: fileSize,
      filePath: filePath,
      timestamp: DateTime.now().toUtc(),
      status: status ?? (outgoing ? ChatMessageStatus.sent : ChatMessageStatus.received),
    );
  }

  static const fromJson = ChatMessageMapper.fromJson;
}
