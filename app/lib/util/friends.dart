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
}
