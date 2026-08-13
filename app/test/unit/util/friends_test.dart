import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/util/friends.dart';
import 'package:test/test.dart';

final _now = DateTime(2026, 1, 1, 12);

Friend _friend(String fingerprint, {Duration? addedAgo}) {
  return Friend(
    id: 'id-$fingerprint',
    fingerprint: fingerprint,
    alias: 'Device $fingerprint',
    customAlias: null,
    lastIp: null,
    lastPort: 53317,
    networkId: null,
    addedAt: _now.subtract(addedAgo ?? Duration.zero),
  );
}

List<String> _order(List<Friend> friends, Map<String, DateTime> lastActivity) {
  return friends.sortedByActivity(lastActivity).map((e) => e.fingerprint).toList();
}

void main() {
  group('sortedByActivity', () {
    test('should put the newest conversation first', () {
      final friends = [_friend('AA'), _friend('BB'), _friend('CC')];
      final order = _order(friends, {
        'AA': _now.subtract(const Duration(days: 2)),
        'BB': _now.subtract(const Duration(minutes: 10)),
        'CC': _now.subtract(const Duration(hours: 3)),
      });
      expect(order, ['BB', 'CC', 'AA']);
    });

    test('should fall back to addedAt for a friend without messages', () {
      // A friend that was just added but never written to still belongs above
      // someone who has been silent for a week.
      final friends = [_friend('AA', addedAgo: const Duration(days: 30)), _friend('BB', addedAgo: Duration.zero)];
      final order = _order(friends, {'AA': _now.subtract(const Duration(days: 7))});
      expect(order, ['BB', 'AA']);
    });

    test('should mix message times and addedAt on the same scale', () {
      final friends = [
        _friend('AA', addedAgo: const Duration(days: 10)),
        _friend('BB', addedAgo: const Duration(days: 10)),
        _friend('CC', addedAgo: const Duration(hours: 1)),
      ];
      final order = _order(friends, {'AA': _now.subtract(const Duration(minutes: 5))});
      expect(order, ['AA', 'CC', 'BB']);
    });

    test('should break ties on the fingerprint', () {
      // [List.sort] is not stable, so equal timestamps need a tiebreaker or the
      // list jumps around between rebuilds.
      final sameTime = _now.subtract(const Duration(minutes: 1));
      final friends = [_friend('CC'), _friend('AA'), _friend('BB')];
      final activity = {'AA': sameTime, 'BB': sameTime, 'CC': sameTime};
      expect(_order(friends, activity), ['AA', 'BB', 'CC']);
      expect(_order(friends.reversed.toList(), activity), ['AA', 'BB', 'CC']);
    });

    test('should not touch the source list', () {
      final friends = [_friend('AA'), _friend('BB')];
      _order(friends, {'BB': _now});
      expect(friends.map((e) => e.fingerprint), ['AA', 'BB']);
    });

    test('should handle an empty list', () {
      expect(<Friend>[].sortedByActivity({}), isEmpty);
    });
  });
}
