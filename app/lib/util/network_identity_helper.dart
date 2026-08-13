import 'package:localsend_app/model/network_identity.dart';

/// Android reports this instead of the SSID when location permission is missing.
const _androidUnknownSsid = '<unknown ssid>';

/// Android reports these instead of the BSSID when location permission is missing.
const _blankBssids = {'02:00:00:00:00:00', '00:00:00:00:00:00'};

/// Strips the literal double quotes Android wraps the SSID in and maps the
/// "permission missing" sentinel to null.
///
/// Without this a device without location permission ends up in a group
/// literally named `<unknown ssid>`, shared with every other such device.
String? normalizeSsid(String? raw) {
  if (raw == null) {
    return null;
  }
  var value = raw.trim();
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    value = value.substring(1, value.length - 1);
  }
  if (value.isEmpty || value == _androidUnknownSsid) {
    return null;
  }
  return value;
}

/// Lowercases the BSSID and maps the "permission missing" sentinels to null.
String? normalizeBssid(String? raw) {
  if (raw == null) {
    return null;
  }
  final value = raw.trim().toLowerCase();
  if (value.isEmpty || _blankBssids.contains(value)) {
    return null;
  }
  return value;
}

/// Derives a `/24` CIDR from an IPv4 address.
///
/// The prefix length is assumed rather than read: `dart:io` NetworkInterface
/// exposes no netmask. Making the assumption explicit here keeps the loss of
/// precision on larger corporate networks visible instead of implied.
String? subnetCidrFromIp(String? ip) {
  if (ip == null) {
    return null;
  }
  final parts = ip.split('.');
  if (parts.length != 4 || parts.any((p) => int.tryParse(p) == null)) {
    return null;
  }
  return '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
}

/// Whether both addresses share the same assumed /24.
bool sameSubnet(String? a, String? b) {
  final subnetA = subnetCidrFromIp(a);
  return subnetA != null && subnetA == subnetCidrFromIp(b);
}

/// Applies the priority chain that turns raw signals into a [NetworkIdentity].
///
/// Ordering rationale:
/// - SSID first because it is stable across every access point of one site.
/// - BSSID is never used as the key: an office has many APs (and one AP has a
///   separate BSSID per radio band), so it would split one site into N groups.
///   It is passed through as a corroborating signal only.
/// - Gateway second: it is the one signal available without extra permissions
///   on all five platforms.
/// - Subnet last, and flagged low-confidence, because `192.168.1.0/24` is the
///   factory default of most consumer routers and collides constantly.
NetworkIdentity buildNetworkIdentity({
  required String? ssid,
  required String? bssid,
  required String? gatewayIp,
  required String? localIp,
  required String? interfaceName,
  required bool vpnActive,
  required DateTime observedAt,
}) {
  final normalizedSsid = normalizeSsid(ssid);
  final normalizedBssid = normalizeBssid(bssid);
  final subnetCidr = subnetCidrFromIp(localIp);

  // A docked laptop has both Wi-Fi and Ethernet up. network_info_plus reports
  // the Wi-Fi interface on Windows and hardcodes en0 on macOS, so the gateway
  // it returns can describe a different LAN than the one traffic actually uses.
  // Only trust it when it agrees with the address we are really bound to.
  final trustedGatewayIp = gatewayIp != null && localIp != null && sameSubnet(gatewayIp, localIp) ? gatewayIp : null;

  final String key;
  final NetworkSignalSource source;
  if (normalizedSsid != null) {
    key = 'ssid:$normalizedSsid';
    source = NetworkSignalSource.ssid;
  } else if (trustedGatewayIp != null) {
    key = 'gw:$trustedGatewayIp|$subnetCidr';
    source = NetworkSignalSource.gateway;
  } else if (subnetCidr != null) {
    key = 'net:$subnetCidr';
    source = NetworkSignalSource.subnet;
  } else if (interfaceName != null && interfaceName.isNotEmpty) {
    key = 'if:$interfaceName';
    source = NetworkSignalSource.interfaceOnly;
  } else {
    key = 'unknown';
    source = NetworkSignalSource.unknown;
  }

  return NetworkIdentity(
    key: key,
    source: source,
    ssid: normalizedSsid,
    bssid: normalizedBssid,
    gatewayIp: trustedGatewayIp,
    subnetCidr: subnetCidr,
    localIp: localIp,
    interfaceName: interfaceName,
    vpnActive: vpnActive,
    observedAt: observedAt,
  );
}
