import 'package:flutter/material.dart';

/// Hairline used to separate the chat panes.
///
/// The chat screen stacks three separators at once — sidebar, conversation
/// header and composer — and at the theme's default strength they frame the
/// messages like a table grid and pull attention away from the content. A
/// fraction of that weight still reads as structure without competing.
Color chatDividerColor(BuildContext context) {
  return Theme.of(context).dividerColor.withValues(alpha: 0.35);
}

/// A [VerticalDivider] at the same reduced weight.
class ChatVerticalDivider extends StatelessWidget {
  final double width;
  final double indent;
  final double endIndent;

  const ChatVerticalDivider({
    this.width = 1,
    this.indent = 0,
    this.endIndent = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: width,
      indent: indent,
      endIndent: endIndent,
      color: chatDividerColor(context),
    );
  }
}
