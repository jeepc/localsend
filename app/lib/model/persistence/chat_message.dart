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

/// One file of a transfer, as it is recorded in a conversation.
typedef ChatFile = ({String fileName, int fileSize, String? filePath, bool isImage});

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

  /// The original name of the first file for file and image messages. The names
  /// of the other files of a multi-file message are not kept: the bubble only
  /// ever shows the first one plus [fileCount].
  final String? fileName;

  /// Total size of every file of the message.
  final int? fileSize;

  /// Where the files landed on this device, in transfer order, as far as they
  /// are still known. Shorter than [fileCount] when a file has no local path,
  /// e.g. one that was never saved.
  final List<String> filePaths;

  /// How many files this message stands for.
  ///
  /// Files that were transferred together become one message instead of one
  /// message per file: they were picked and sent as one action, and one bubble
  /// per file both floods the conversation and made the concurrent appends of a
  /// multi-file transfer overwrite each other.
  final int fileCount;

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
    this.filePaths = const [],
    this.fileCount = 1,
    required this.timestamp,
    required this.status,
  });

  /// The first file of the message, which is the only one for the ordinary
  /// single-file case.
  String? get filePath => filePaths.isEmpty ? null : filePaths.first;

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
      timestamp: timestamp,
      status: ChatMessageStatus.received,
    );
  }

  /// One message for all [files] of a transfer. Must not be called with an
  /// empty list.
  factory ChatMessage.files({
    required String peerFingerprint,
    required bool outgoing,
    required List<ChatFile> files,
    ChatMessageStatus? status,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? _uuid.v4(),
      peerFingerprint: peerFingerprint,
      outgoing: outgoing,
      // Only a batch in which every file is an image counts as one, so a mixed
      // selection does not claim to be a picture.
      type: files.every((file) => file.isImage) ? ChatMessageType.image : ChatMessageType.file,
      text: null,
      fileName: files.first.fileName,
      fileSize: files.fold<int>(0, (sum, file) => sum + file.fileSize),
      filePaths: [
        for (final file in files)
          if (file.filePath != null) file.filePath!,
      ],
      fileCount: files.length,
      timestamp: DateTime.now().toUtc(),
      status: status ?? (outgoing ? ChatMessageStatus.sent : ChatMessageStatus.received),
    );
  }

  /// Folds another file of the same transfer into this message, for the
  /// receiving side, where the files arrive one after another.
  ChatMessage withFile(ChatFile file) {
    return copyWith(
      type: type == ChatMessageType.image && file.isImage ? ChatMessageType.image : ChatMessageType.file,
      fileSize: (fileSize ?? 0) + file.fileSize,
      filePaths: [
        ...filePaths,
        if (file.filePath != null) file.filePath!,
      ],
      fileCount: fileCount + 1,
    );
  }

  static const fromJson = ChatMessageMapper.fromJson;
}
