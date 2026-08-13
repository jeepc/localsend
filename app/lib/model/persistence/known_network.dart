import 'package:dart_mappable/dart_mappable.dart';
import 'package:localsend_app/model/network_identity.dart';
import 'package:uuid/uuid.dart';

part 'known_network.mapper.dart';

const _uuid = Uuid();

/// Score at or above which an observed [NetworkIdentity] is considered to be
/// the same LAN as a stored [KnownNetwork].
///
/// Deliberately above the subnet-only score: `192.168.1.0/24` is the default of
/// most consumer routers, so a subnet match alone must not silently merge the
/// user's home and office groups.
const knownNetworkMatchThreshold = 50;

/// A LAN the user has named ("公司", "家里", ...).
///
/// Friends are grouped by these. One record accumulates every key ever observed
/// for the network, so roaming between access points or gaining a better signal
/// later does not create a duplicate group.
@MappableClass()
class KnownNetwork with KnownNetworkMappable {
  final String id;

  /// User-given label, e.g. "公司" or "家里".
  final String label;

  /// Every [NetworkIdentity.key] ever observed for this network.
  final List<String> keys;

  /// Access point MACs seen on this network. Corroborating signal only.
  final List<String> bssids;

  final String? ssid;
  final String? gatewayIp;
  final String? subnetCidr;
  final DateTime lastSeen;

  const KnownNetwork({
    required this.id,
    required this.label,
    required this.keys,
    required this.bssids,
    required this.ssid,
    required this.gatewayIp,
    required this.subnetCidr,
    required this.lastSeen,
  });

  factory KnownNetwork.fromIdentity({
    required String label,
    required NetworkIdentity identity,
  }) {
    return KnownNetwork(
      id: _uuid.v1(),
      label: label,
      keys: [identity.key],
      bssids: identity.bssid != null ? [identity.bssid!] : const [],
      ssid: identity.ssid,
      gatewayIp: identity.gatewayIp,
      subnetCidr: identity.subnetCidr,
      lastSeen: DateTime.now().toUtc(),
    );
  }

  /// How strongly [identity] indicates that we are on this network.
  ///
  /// Higher is better; see [knownNetworkMatchThreshold] for the accept cutoff.
  int matchScore(NetworkIdentity identity) {
    if (identity.isUnknown) {
      return 0;
    }
    if (keys.contains(identity.key)) {
      return 100;
    }
    if (identity.bssid != null && bssids.contains(identity.bssid)) {
      return 80;
    }
    if (identity.ssid != null && identity.ssid == ssid) {
      return 60;
    }
    if (identity.gatewayIp != null && identity.gatewayIp == gatewayIp && identity.subnetCidr == subnetCidr) {
      return 50;
    }
    if (identity.subnetCidr != null && identity.subnetCidr == subnetCidr) {
      // Weak on purpose: below the threshold, because this collides constantly.
      return 20;
    }
    return 0;
  }

  /// Absorbs the signals of [identity] so the next observation matches at 100.
  KnownNetwork mergeIdentity(NetworkIdentity identity) {
    return copyWith(
      keys: keys.contains(identity.key) ? keys : [...keys, identity.key],
      bssids: identity.bssid == null || bssids.contains(identity.bssid) ? bssids : [...bssids, identity.bssid!],
      ssid: ssid ?? identity.ssid,
      gatewayIp: gatewayIp ?? identity.gatewayIp,
      subnetCidr: subnetCidr ?? identity.subnetCidr,
      lastSeen: DateTime.now().toUtc(),
    );
  }

  static const fromJson = KnownNetworkMapper.fromJson;
}
