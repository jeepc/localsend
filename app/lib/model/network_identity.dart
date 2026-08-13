import 'package:dart_mappable/dart_mappable.dart';

part 'network_identity.mapper.dart';

/// Which signal produced [NetworkIdentity.key].
///
/// Ordered from most to least discriminating. The tier is kept around because
/// a low-confidence identity (e.g. [NetworkSignalSource.subnet], where
/// `192.168.1.0/24` collides between home and office) must be presented
/// differently in the UI than a high-confidence one.
@MappableEnum(defaultValue: NetworkSignalSource.unknown)
enum NetworkSignalSource {
  ssid,
  gateway,
  subnet,
  interfaceOnly,
  unknown,
}

/// A snapshot of the LAN this device is currently attached to.
///
/// This is deliberately *not* persisted: it is re-observed on every network
/// change. Persistence happens in `KnownNetwork`, which stores the user-given
/// label plus every signal ever observed for that network, so a snapshot can be
/// matched back to it even when signal availability changes (docked vs. not,
/// VPN on/off, permission granted later).
@MappableClass()
class NetworkIdentity with NetworkIdentityMappable {
  /// Best-effort stable key for the LAN we are on right now. Never empty.
  final String key;

  /// Which tier of the priority chain produced [key].
  final NetworkSignalSource source;

  /// Normalized SSID. Android wraps it in literal double quotes and reports
  /// `<unknown ssid>` without location permission; both are mapped to null.
  final String? ssid;

  /// The access point MAC, lowercased.
  ///
  /// Always null on Linux: `network_info_plus` returns the *local* Wi-Fi card's
  /// permanent hardware address there, which is identical on every network and
  /// would merge all LANs into one group.
  ///
  /// Never used as [key] — an office has multiple APs (and separate BSSIDs per
  /// radio band), so keying on it would split one site into many groups. It is
  /// only kept as a corroborating signal.
  final String? bssid;

  final String? gatewayIp;

  /// Assumed /24, because `dart:io` NetworkInterface exposes no netmask.
  final String? subnetCidr;

  final String? localIp;
  final String? interfaceName;

  /// While a VPN is up the default route points at the tunnel, so a fresh
  /// observation would describe the VPN rather than the LAN.
  final bool vpnActive;

  final DateTime observedAt;

  const NetworkIdentity({
    required this.key,
    required this.source,
    required this.ssid,
    required this.bssid,
    required this.gatewayIp,
    required this.subnetCidr,
    required this.localIp,
    required this.interfaceName,
    required this.vpnActive,
    required this.observedAt,
  });

  static final unknown = NetworkIdentity(
    key: 'unknown',
    source: NetworkSignalSource.unknown,
    ssid: null,
    bssid: null,
    gatewayIp: null,
    subnetCidr: null,
    localIp: null,
    interfaceName: null,
    vpnActive: false,
    observedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  bool get isUnknown => source == NetworkSignalSource.unknown;

  /// True when the key is weak enough that two physically different LANs can
  /// collide on it, so the user needs an escape hatch to split the group.
  bool get isLowConfidence => source == NetworkSignalSource.subnet || source == NetworkSignalSource.interfaceOnly;

  static const fromJson = NetworkIdentityMapper.fromJson;
}
