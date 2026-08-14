import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';

/// The message composer: a growing text field plus the attachment buttons.
class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final VoidCallback onPickFiles;
  final VoidCallback onPickImages;
  final bool enabled;

  const ChatInputBar({
    required this.onSubmit,
    required this.onPickFiles,
    required this.onPickImages,
    required this.enabled,
    super.key,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) {
      return;
    }
    _controller.clear();
    widget.onSubmit(text);
    // Keep typing without reaching for the mouse again.
    _focusNode.requestFocus();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    // Shift+Enter inserts a newline, plain Enter sends. On touch platforms the
    // on-screen keyboard's return key should insert a newline instead.
    if (!checkPlatformIsDesktop() || HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    _submit();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The filled text field is shape enough to read as its own band; a rule on
      // top would only double up with the field's own edge.
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: t.chatTab.sendFile,
              icon: const Icon(Icons.attach_file),
              onPressed: widget.enabled ? widget.onPickFiles : null,
            ),
            if (checkPlatformWithGallery())
              IconButton(
                tooltip: t.chatTab.sendImage,
                icon: const Icon(Icons.image_outlined),
                onPressed: widget.enabled ? widget.onPickImages : null,
              ),
            Expanded(
              child: Focus(
                onKeyEvent: _onKeyEvent,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: t.chatTab.inputHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: widget.enabled ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
