import 'package:collection/collection.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_isolates/model/device.dart';

extension FriendsExt on Iterable<Friend> {
  /// Returns the friend matching [device] or null if not found.
  ///
  /// Matched on the certificate fingerprint, the same key favorites use.
  Friend? findDevice(Device device) {
    return firstWhereOrNull((e) => e.fingerprint == device.fingerprint);
  }

  bool containsDevice(Device device) {
    return any((e) => e.fingerprint == device.fingerprint);
  }

  Friend? findByFingerprint(String fingerprint) {
    return firstWhereOrNull((e) => e.fingerprint == fingerprint);
  }

  bool containsFingerprint(String fingerprint) {
    return any((e) => e.fingerprint == fingerprint);
  }

  /// Newest conversation first, so whoever the user talked to last is on top.
  ///
  /// [lastActivity] maps a fingerprint to the timestamp of the newest message
  /// of that conversation; a friend without any message falls back to
  /// [Friend.addedAt]. Equal timestamps break ties on the fingerprint because
  /// [List.sort] is not stable — otherwise the order could jump around between
  /// rebuilds.
  List<Friend> sortedByActivity(Map<String, DateTime> lastActivity) {
    DateTime keyOf(Friend friend) => lastActivity[friend.fingerprint] ?? friend.addedAt;

    return toList()..sort((a, b) {
      final byTime = keyOf(b).compareTo(keyOf(a));
      return byTime != 0 ? byTime : a.fingerprint.compareTo(b.fingerprint);
    });
  }
}
