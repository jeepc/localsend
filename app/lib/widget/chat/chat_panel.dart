import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/provider/chat/presence_provider.dart';
import 'package:localsend_app/widget/chat/chat_bubble.dart';
import 'package:localsend_app/widget/chat/chat_divider.dart';
import 'package:localsend_app/widget/chat/chat_input_bar.dart';

/// The right-hand (or lower) half of the chat tab: header, transcript, composer.
class ChatPanel extends StatefulWidget {
  final Friend friend;
  final List<ChatMessage> messages;
  final PresenceStatus status;
  final ValueChanged<String> onSubmit;
  final VoidCallback onPickFiles;
  final VoidCallback onPickImages;
  final ValueChanged<ChatMessage> onResend;

  /// Opens one file of a message; a message can stand for several of them.
  final void Function(ChatMessage message, String filePath) onOpenFile;
  final VoidCallback onClearConversation;

  const ChatPanel({
    required this.friend,
    required this.messages,
    required this.status,
    required this.onSubmit,
    required this.onPickFiles,
    required this.onPickImages,
    required this.onResend,
    required this.onOpenFile,
    required this.onClearConversation,
    super.key,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length || widget.friend.fingerprint != oldWidget.friend.fingerprint) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // The list is reversed, so "bottom" is offset zero.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: chatDividerColor(context))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.friend.displayName, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    // Nothing is claimed while the status is still unknown, so
                    // opening a chat never accuses a reachable friend of being
                    // away.
                    if (widget.status != PresenceStatus.online)
                      Text(
                        widget.status == PresenceStatus.offline ? t.chatTab.offlineHint : t.chatTab.checking,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<void>(
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    onTap: widget.onClearConversation,
                    child: Text(t.chatTab.clearConversation),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: Text(
                    t.chatTab.emptyConversation,
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  // Reversed so the newest message is visible without measuring
                  // the list, and so growth pins to the bottom.
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.messages[widget.messages.length - 1 - index];
                    return ChatBubble(
                      message: message,
                      onResend: message.status == ChatMessageStatus.failed ? () => widget.onResend(message) : null,
                      onOpenFile: (filePath) => widget.onOpenFile(message, filePath),
                    );
                  },
                ),
        ),
        ChatInputBar(
          onSubmit: widget.onSubmit,
          onPickFiles: widget.onPickFiles,
          onPickImages: widget.onPickImages,
          enabled: true,
        ),
      ],
    );
  }
}
