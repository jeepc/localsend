import 'package:dart_mappable/dart_mappable.dart';

part 'pending_friend_request.mapper.dart';

/// An outgoing friend request that is still waiting for the peer's answer.
///
/// Persisted so a reply that arrives after an app restart can still be matched
/// back to the request that caused it.
@MappableClass()
class PendingFriendRequest with PendingFriendRequestMappable {
  final String requestId;

  /// Certificate fingerprint of the device the request was sent to.
  final String fingerprint;

  /// Alias of the target at the time the request was sent, for the UI.
  final String alias;

  final String? ip;
  final int port;

  /// The group the friend should land in once the peer accepts.
  ///
  /// Resolved when the request is sent, which is a moment the user is present
  /// and can name an unknown network. The answer may arrive much later, when
  /// prompting would be intrusive.
  final String? networkId;

  final DateTime createdAt;

  const PendingFriendRequest({
    required this.requestId,
    required this.fingerprint,
    required this.alias,
    required this.ip,
    required this.port,
    required this.networkId,
    required this.createdAt,
  });

  static const fromJson = PendingFriendRequestMapper.fromJson;
}
