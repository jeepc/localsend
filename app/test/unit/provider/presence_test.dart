import 'package:localsend_app/provider/chat/presence_provider.dart';
import 'package:test/test.dart';

final _now = DateTime(2026, 1, 1, 12);

PresenceStatus statusOf({
  String fingerprint = 'AA',
  Duration? seenAgo,
  Set<String> signaling = const {},
  bool firstRoundDone = true,
}) {
  return presenceStatusOf(
    fingerprint: fingerprint,
    lastSeen: seenAgo == null ? const {} : {'AA': _now.subtract(seenAgo)},
    signalingFingerprints: signaling,
    now: _now,
    firstRoundDone: firstRoundDone,
  );
}

void main() {
  group('presenceStatusOf', () {
    test('should be online while the last confirmation is fresh', () {
      expect(statusOf(seenAgo: Duration.zero), PresenceStatus.online);
      expect(statusOf(seenAgo: presenceTimeout ~/ 2), PresenceStatus.online);
    });

    test('should go offline once the confirmation aged out', () {
      // The whole point of the change: nothing reports a device leaving, so a
      // stale stamp is the only evidence there is.
      expect(statusOf(seenAgo: presenceTimeout * 2), PresenceStatus.offline);
    });

    test('should treat the timeout itself as expired', () {
      expect(statusOf(seenAgo: presenceTimeout), PresenceStatus.offline);
      expect(statusOf(seenAgo: presenceTimeout - const Duration(seconds: 1)), PresenceStatus.online);
    });

    test('should be offline for a friend that was never confirmed', () {
      expect(statusOf(), PresenceStatus.offline);
    });

    group('before the first round came back', () {
      test('should be unknown instead of offline', () {
        // Entering the chat tab must not accuse everyone of being away while
        // the first heartbeat is still in flight.
        expect(statusOf(firstRoundDone: false), PresenceStatus.unknown);
        expect(statusOf(seenAgo: presenceTimeout * 2, firstRoundDone: false), PresenceStatus.unknown);
      });

      test('should still be online on a fresh confirmation', () {
        expect(statusOf(seenAgo: Duration.zero, firstRoundDone: false), PresenceStatus.online);
      });
    });

    group('signaling devices', () {
      test('should be online regardless of the timeout', () {
        // They are never discovered over the LAN, so they get no stamp; the
        // signaling server is what withdraws them.
        expect(statusOf(signaling: {'AA'}), PresenceStatus.online);
        expect(statusOf(seenAgo: presenceTimeout * 10, signaling: {'AA'}), PresenceStatus.online);
      });

      test('should ignore case', () {
        expect(statusOf(fingerprint: 'aa', signaling: {'AA'}), PresenceStatus.online);
      });
    });

    test('should match a differently cased fingerprint', () {
      // Certificate fingerprints are uppercase hex, but with encryption off the
      // peer reports its own and nothing enforces the case.
      expect(statusOf(fingerprint: 'aa', seenAgo: Duration.zero), PresenceStatus.online);
    });

    test('should not confuse two different fingerprints', () {
      expect(statusOf(fingerprint: 'BB', seenAgo: Duration.zero), PresenceStatus.offline);
    });
  });
}
