import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/widget/dialogs/chat_files_dialog.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';

const _textMaxWidth = 420.0;

/// File bubbles hold a single ellipsized line plus the size, so they are kept
/// clearly narrower than text bubbles instead of stretching across the pane.
const _fileMaxWidth = 260.0;

/// One message in a conversation: own messages on the right, the peer's on the
/// left, the way every chat app does it.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onResend;

  /// Opens one of the files of the message, picked by the user when there is
  /// more than one.
  final void Function(String filePath)? onOpenFile;

  const ChatBubble({
    required this.message,
    this.onResend,
    this.onOpenFile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outgoing = message.outgoing;
    final background = outgoing ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final foreground = outgoing ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: outgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: message.type == ChatMessageType.text ? _textMaxWidth : _fileMaxWidth),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(outgoing ? 12 : 2),
                      bottomRight: Radius.circular(outgoing ? 2 : 12),
                    ),
                  ),
                  child: switch (message.type) {
                    ChatMessageType.text => SelectableText(
                      message.text ?? '',
                      style: TextStyle(color: foreground),
                    ),
                    ChatMessageType.file || ChatMessageType.image => _FileContent(
                      message: message,
                      foreground: foreground,
                      onOpenFile: onOpenFile,
                    ),
                  },
                ),
                const SizedBox(height: 2),
                _Footer(message: message, onResend: onResend),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  final ChatMessage message;
  final Color foreground;
  final void Function(String filePath)? onOpenFile;

  const _FileContent({
    required this.message,
    required this.foreground,
    required this.onOpenFile,
  });

  /// Files that were sent together are one message, so the bubble names the
  /// first file and says how many there are in total.
  String get _label {
    final fileName = message.fileName ?? t.chatTab.fileMessage;
    return message.fileCount > 1 ? t.chatTab.multipleFiles(fileName: fileName, count: message.fileCount) : fileName;
  }

  Future<void> _open(BuildContext context) async {
    final filePaths = message.filePaths;
    if (filePaths.length == 1) {
      onOpenFile!(filePaths.first);
      return;
    }

    // Which of them the user meant is only clear once they say so.
    final picked = await ChatFilesDialog.open(context, title: _label, filePaths: filePaths);
    if (picked != null) {
      onOpenFile!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenFile != null && message.filePaths.isNotEmpty ? () => _open(context) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            message.type == ChatMessageType.image ? Icons.image : Icons.insert_drive_file,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _label,
                  style: TextStyle(color: foreground),
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  Text(
                    message.fileSize!.asReadableFileSize,
                    style: TextStyle(color: foreground.withValues(alpha: 0.7), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onResend;

  const _Footer({required this.message, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageTag = LocaleSettings.currentLocale.languageTag;
    final time = DateFormat.jm(languageTag).format(message.timestamp.toLocal());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
        if (message.status == ChatMessageStatus.sending) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.colorScheme.outline),
          ),
        ] else if (message.status == ChatMessageStatus.failed) ...[
          const SizedBox(width: 6),
          Text(
            t.chatTab.notDelivered,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.error),
          ),
          if (onResend != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onResend,
              child: Text(
                t.chatTab.resend,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
