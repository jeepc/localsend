import 'package:refena_flutter/refena_flutter.dart';

/// A file drag that is currently hovering over the chat tab.
///
/// The window has a single drop target, so the friend list cannot react to the
/// drag on its own: the drop handler resolves the row under the cursor and
/// publishes it here, which is what lets the list highlight it and the
/// conversation hint say where the files would go.
typedef ChatDropState = ({bool dragging, String? hoveredFingerprint});

final chatDropProvider = NotifierProvider<ChatDropService, ChatDropState>((ref) {
  return ChatDropService();
});

class ChatDropService extends Notifier<ChatDropState> {
  @override
  ChatDropState init() => (dragging: false, hoveredFingerprint: null);

  /// [fingerprint] is the friend below the cursor, or null while the drag is
  /// anywhere else.
  void hover(String? fingerprint) {
    state = (dragging: true, hoveredFingerprint: fingerprint);
  }

  void stop() {
    state = (dragging: false, hoveredFingerprint: null);
  }
}
