import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Runs a presence round now, for when waiting for the next one is too slow.
///
/// Mirrors the send tab's scan button, down to the spinning sync icon, so the
/// two "check the network again" affordances look the same.
class PresenceRefreshButton extends StatelessWidget {
  final bool refreshing;
  final VoidCallback onPressed;

  const PresenceRefreshButton({
    required this.refreshing,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final animations = context.ref.watch(animationProvider);

    return Tooltip(
      message: t.chatTab.refresh,
      child: RotatingWidget(
        duration: const Duration(seconds: 2),
        spinning: refreshing && animations,
        reverse: true,
        child: CustomIconButton(
          onPressed: onPressed,
          child: const Icon(Icons.sync),
        ),
      ),
    );
  }
}
