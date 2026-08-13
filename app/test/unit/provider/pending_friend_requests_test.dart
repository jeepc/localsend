import 'package:localsend_app/model/persistence/pending_friend_request.dart';
import 'package:localsend_app/provider/chat/pending_friend_requests_provider.dart';
import 'package:test/test.dart';

PendingFriendRequest request({
  required String requestId,
  required String fingerprint,
  required Duration age,
}) {
  return PendingFriendRequest(
    requestId: requestId,
    fingerprint: fingerprint,
    alias: 'peer',
    ip: '192.168.1.2',
    port: 53317,
    networkId: null,
    createdAt: DateTime.now().toUtc().subtract(age),
  );
}

void main() {
  group('active', () {
    test('should keep a fresh request', () {
      final requests = [request(requestId: 'r1', fingerprint: 'AA', age: Duration.zero)];

      expect(requests.active.map((e) => e.requestId), ['r1']);
    });

    test('should drop a request that never got an answer', () {
      // Otherwise the add button stays hidden forever with no way to recover.
      final requests = [
        request(requestId: 'r1', fingerprint: 'AA', age: pendingFriendRequestTimeout + const Duration(seconds: 1)),
      ];

      expect(requests.active, isEmpty);
    });

    test('should not affect matching a late answer', () {
      final stale = request(requestId: 'r1', fingerprint: 'AA', age: pendingFriendRequestTimeout * 10);
      final requests = [stale];

      expect(requests.active, isEmpty);
      expect(requests.findByRequestId('r1'), isNotNull);
      expect(requests.findByFingerprint('AA'), isNotNull);
    });
  });

  group('findByFingerprint', () {
    test('should ignore case', () {
      // Certificate fingerprints are uppercase hex, but a peer discovered over
      // multicast may report a differently cased one.
      final requests = [request(requestId: 'r1', fingerprint: 'abcdef', age: Duration.zero)];

      expect(requests.findByFingerprint('ABCDEF'), isNotNull);
    });

    test('should return null for an unknown peer', () {
      final requests = [request(requestId: 'r1', fingerprint: 'AA', age: Duration.zero)];

      expect(requests.findByFingerprint('BB'), isNull);
    });
  });
}
