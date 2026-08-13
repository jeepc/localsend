import 'package:refena_flutter/refena_flutter.dart';

/// Fingerprint of the friend whose conversation is open, or null when none is
/// selected yet.
final selectedFriendProvider = NotifierProvider<SelectedFriendService, String?>((ref) {
  return SelectedFriendService();
});

class SelectedFriendService extends Notifier<String?> {
  @override
  String? init() => null;

  void select(String? fingerprint) {
    state = fingerprint;
  }
}
