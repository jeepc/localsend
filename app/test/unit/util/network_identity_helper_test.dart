import 'package:localsend_app/model/network_identity.dart';
import 'package:localsend_app/util/network_identity_helper.dart';
import 'package:test/test.dart';

NetworkIdentity build({
  String? ssid,
  String? bssid,
  String? gatewayIp,
  String? localIp,
  String? interfaceName,
  bool vpnActive = false,
}) {
  return buildNetworkIdentity(
    ssid: ssid,
    bssid: bssid,
    gatewayIp: gatewayIp,
    localIp: localIp,
    interfaceName: interfaceName,
    vpnActive: vpnActive,
    observedAt: DateTime.utc(2026),
  );
}

void main() {
  group('normalizeSsid', () {
    test('should strip the quotes Android wraps the SSID in', () {
      expect(normalizeSsid('"MyWifi"'), 'MyWifi');
    });

    test('should map the permission-missing sentinel to null', () {
      expect(normalizeSsid('<unknown ssid>'), isNull);
    });

    test('should map empty values to null', () {
      expect(normalizeSsid(null), isNull);
      expect(normalizeSsid(''), isNull);
      expect(normalizeSsid('""'), isNull);
    });

    test('should keep a plain SSID', () {
      expect(normalizeSsid('Office 5G'), 'Office 5G');
    });
  });

  group('normalizeBssid', () {
    test('should lowercase', () {
      expect(normalizeBssid('AA:BB:CC:DD:EE:FF'), 'aa:bb:cc:dd:ee:ff');
    });

    test('should map the permission-missing sentinels to null', () {
      expect(normalizeBssid('02:00:00:00:00:00'), isNull);
      expect(normalizeBssid('00:00:00:00:00:00'), isNull);
    });
  });

  group('subnetCidrFromIp', () {
    test('should assume a /24', () {
      expect(subnetCidrFromIp('192.168.1.42'), '192.168.1.0/24');
    });

    test('should reject non IPv4 input', () {
      expect(subnetCidrFromIp(null), isNull);
      expect(subnetCidrFromIp('fe80::1'), isNull);
      expect(subnetCidrFromIp('192.168.1'), isNull);
      expect(subnetCidrFromIp('a.b.c.d'), isNull);
    });
  });

  group('buildNetworkIdentity priority chain', () {
    test('should prefer the SSID', () {
      final identity = build(ssid: '"Office"', gatewayIp: '192.168.1.1', localIp: '192.168.1.42');

      expect(identity.source, NetworkSignalSource.ssid);
      expect(identity.key, 'ssid:Office');
    });

    test('should fall back to the gateway when there is no SSID', () {
      final identity = build(gatewayIp: '192.168.1.1', localIp: '192.168.1.42');

      expect(identity.source, NetworkSignalSource.gateway);
      expect(identity.key, 'gw:192.168.1.1|192.168.1.0/24');
    });

    test('should fall back to the subnet when there is no gateway', () {
      final identity = build(localIp: '10.0.0.5');

      expect(identity.source, NetworkSignalSource.subnet);
      expect(identity.key, 'net:10.0.0.0/24');
      expect(identity.isLowConfidence, isTrue);
    });

    test('should fall back to the interface name when there is no address', () {
      final identity = build(interfaceName: 'eth0');

      expect(identity.source, NetworkSignalSource.interfaceOnly);
      expect(identity.key, 'if:eth0');
    });

    test('should report unknown when nothing is available', () {
      final identity = build();

      expect(identity.source, NetworkSignalSource.unknown);
      expect(identity.isUnknown, isTrue);
    });

    test('should never use the BSSID as the key', () {
      // One site has many access points, each with its own BSSID (and one per
      // radio band), so keying on it would split a single office into N groups.
      final identity = build(bssid: 'AA:BB:CC:DD:EE:FF', localIp: '192.168.1.42');

      expect(identity.key, 'net:192.168.1.0/24');
      expect(identity.bssid, 'aa:bb:cc:dd:ee:ff');
    });

    test('should drop a gateway from a different subnet than the bound address', () {
      // Docked laptop: the plugin reports the Wi-Fi gateway while traffic goes
      // over Ethernet. Mixing the two would describe a LAN that does not exist.
      final identity = build(gatewayIp: '192.168.1.1', localIp: '10.20.30.40');

      expect(identity.gatewayIp, isNull);
      expect(identity.source, NetworkSignalSource.subnet);
      expect(identity.key, 'net:10.20.30.0/24');
    });

    test('should not build a group out of the unknown-ssid sentinel', () {
      final identity = build(ssid: '<unknown ssid>', localIp: '192.168.1.42');

      expect(identity.ssid, isNull);
      expect(identity.key, isNot(contains('unknown ssid')));
    });
  });
}
