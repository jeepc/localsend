import 'package:localsend_app/model/network_identity.dart';
import 'package:localsend_app/model/persistence/known_network.dart';
import 'package:localsend_app/util/network_identity_helper.dart';
import 'package:test/test.dart';

NetworkIdentity identity({
  String? ssid,
  String? bssid,
  String? gatewayIp,
  String? localIp,
}) {
  return buildNetworkIdentity(
    ssid: ssid,
    bssid: bssid,
    gatewayIp: gatewayIp,
    localIp: localIp,
    interfaceName: null,
    vpnActive: false,
    observedAt: DateTime.utc(2026),
  );
}

void main() {
  group('matchScore', () {
    test('should score a known key highest', () {
      final observed = identity(ssid: 'Office', localIp: '192.168.1.42');
      final network = KnownNetwork.fromIdentity(label: 'Office', identity: observed);

      expect(network.matchScore(observed), 100);
    });

    test('should match on a known BSSID even when the key changed', () {
      final atFirstAp = identity(ssid: 'Office', bssid: 'aa:bb:cc:dd:ee:ff', localIp: '192.168.1.42');
      final network = KnownNetwork.fromIdentity(label: 'Office', identity: atFirstAp);

      // SSID gone (permission revoked), address changed, but the AP is the same.
      final later = identity(bssid: 'aa:bb:cc:dd:ee:ff', localIp: '10.0.0.9');

      expect(network.matchScore(later), 80);
    });

    test('should still match an SSID-keyed network after a DHCP change', () {
      // The key is derived from the SSID, so a new lease does not affect it.
      final network = KnownNetwork.fromIdentity(
        label: 'Office',
        identity: identity(ssid: 'Office', localIp: '192.168.1.42'),
      );

      expect(network.matchScore(identity(ssid: 'Office', localIp: '172.16.0.3')), 100);
    });

    test('should match on the SSID when the stored keys do not contain it', () {
      // Persisted records from an older version (or a pruned key list) can hold
      // an SSID without the matching key.
      final network = KnownNetwork(
        id: 'id',
        label: 'Office',
        keys: const ['net:192.168.1.0/24'],
        bssids: const [],
        ssid: 'Office',
        gatewayIp: null,
        subnetCidr: '192.168.1.0/24',
        lastSeen: DateTime.utc(2026),
      );

      expect(network.matchScore(identity(ssid: 'Office', localIp: '172.16.0.3')), 60);
    });

    test('should score a subnet-only match below the accept threshold', () {
      // 192.168.1.0/24 is the factory default of most consumer routers, so home
      // and office collide on it constantly. It must not silently merge them.
      final home = KnownNetwork.fromIdentity(
        label: 'Home',
        identity: identity(gatewayIp: '192.168.1.1', localIp: '192.168.1.10'),
      );
      final office = identity(gatewayIp: '192.168.1.254', localIp: '192.168.1.77');

      expect(home.matchScore(office), lessThan(knownNetworkMatchThreshold));
    });

    test('should accept a gateway plus subnet match', () {
      final network = KnownNetwork.fromIdentity(
        label: 'Home',
        identity: identity(gatewayIp: '192.168.1.1', localIp: '192.168.1.10'),
      );
      final laterSameRouter = identity(gatewayIp: '192.168.1.1', localIp: '192.168.1.55');

      expect(network.matchScore(laterSameRouter), greaterThanOrEqualTo(knownNetworkMatchThreshold));
    });

    test('should not match an unknown identity', () {
      final network = KnownNetwork.fromIdentity(
        label: 'Home',
        identity: identity(ssid: 'Home', localIp: '192.168.1.10'),
      );

      expect(network.matchScore(identity()), 0);
    });
  });

  group('mergeIdentity', () {
    test('should absorb a better signal so the next observation matches exactly', () {
      // Recorded when only the gateway was readable; later the SSID becomes
      // available (permission granted, or moved off Ethernet) and the key
      // changes tier. Without merging, that would look like a new network.
      final network = KnownNetwork.fromIdentity(
        label: 'Office',
        identity: identity(gatewayIp: '192.168.1.1', localIp: '192.168.1.42'),
      );

      final upgraded = identity(ssid: 'Office', bssid: '11:22:33:44:55:66', gatewayIp: '192.168.1.1', localIp: '192.168.1.42');
      expect(network.matchScore(upgraded), 50);

      final merged = network.mergeIdentity(upgraded);

      expect(merged.matchScore(upgraded), 100);
      expect(merged.bssids, contains('11:22:33:44:55:66'));
      expect(merged.ssid, 'Office');
      expect(merged.id, network.id);
      expect(merged.label, 'Office');
    });

    test('should not duplicate keys', () {
      final observed = identity(ssid: 'Office', bssid: 'aa:bb:cc:dd:ee:ff', localIp: '192.168.1.42');
      final network = KnownNetwork.fromIdentity(label: 'Office', identity: observed);

      final merged = network.mergeIdentity(observed).mergeIdentity(observed);

      expect(merged.keys.length, 1);
      expect(merged.bssids.length, 1);
    });
  });
}
