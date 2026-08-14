import 'package:flutter/material.dart';

/// Hairline used to separate the chat panes.
///
/// The header and the composer carry no line at all — whitespace does that job,
/// and a line there only framed the messages like a table cell. What is left is
/// reserved for the boundary between two independently scrolling areas, where
/// nothing else marks the edge. At that job a barely-there tint is enough, so
/// the weight stays far below the theme default.
Color chatDividerColor(BuildContext context) {
  return Theme.of(context).dividerColor.withValues(alpha: 0.12);
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
