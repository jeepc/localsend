import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Marks a friend list entry as the drop destination for that friend.
///
/// Nesting a second `DropTarget` inside the window-wide one would not work:
/// every target hit-tests the drag on its own, so both would fire for the same
/// drop. The friend rows therefore tag themselves and the drop handler resolves
/// the recipient from the drop position with [friendFingerprintAt].
class FriendDropZone extends StatelessWidget {
  final String fingerprint;
  final Widget child;

  const FriendDropZone({
    required this.fingerprint,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: _FriendDropTag(fingerprint),
      // The row is a drop target as a whole, including the gaps its children
      // leave. Hit testing still reaches the children first, so tapping and
      // long pressing are unaffected.
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _FriendDropTag {
  final String fingerprint;

  const _FriendDropTag(this.fingerprint);
}

/// The friend whose [FriendDropZone] sits at [globalPosition], or null if the
/// position is not on the friend list.
///
/// [globalPosition] is in logical pixels, which is what `desktop_drop` reports.
String? friendFingerprintAt(BuildContext context, Offset globalPosition) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, globalPosition, View.of(context).viewId);
  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderMetaData) {
      final tag = target.metaData;
      if (tag is _FriendDropTag) {
        return tag.fingerprint;
      }
    }
  }
  return null;
}
