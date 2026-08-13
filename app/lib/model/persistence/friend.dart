import 'package:dart_mappable/dart_mappable.dart';
import 'package:uuid/uuid.dart';

part 'friend.mapper.dart';

const _uuid = Uuid();

/// A device the user has an accepted, mutual relationship with.
///
/// Identity is the peer's mTLS certificate fingerprint, which cannot be
/// spoofed, so it is also the key of the chat conversation. This is the same
/// key `FavoriteDevice` matches on, but the two are intentionally separate:
/// favorites are quick-send targets, friends are chat partners.
@MappableClass()
class Friend with FriendMappable {
  final String id;
  final String fingerprint;

  /// Last known alias reported by the device.
  final String alias;

  /// User-given nickname. When set it wins over [alias] in the UI.
  final String? customAlias;

  final String? lastIp;
  final int lastPort;

  /// The [KnownNetwork] this friendship was established on.
  ///
  /// Nullable so a friend can still be added while the current LAN is
  /// unidentified; the user can assign a group later.
  final String? networkId;

  final DateTime addedAt;

  const Friend({
    required this.id,
    required this.fingerprint,
    required this.alias,
    required this.customAlias,
    required this.lastIp,
    required this.lastPort,
    required this.networkId,
    required this.addedAt,
  });

  factory Friend.fromValues({
    required String fingerprint,
    required String alias,
    required String? ip,
    required int port,
    required String? networkId,
  }) {
    return Friend(
      id: _uuid.v1(),
      fingerprint: fingerprint,
      alias: alias,
      customAlias: null,
      lastIp: ip,
      lastPort: port,
      networkId: networkId,
      addedAt: DateTime.now().toUtc(),
    );
  }

  /// The name to show in the friend list and chat header.
  String get displayName => customAlias ?? alias;

  static const fromJson = FriendMapper.fromJson;
}
