import 'package:collection/collection.dart';
import 'package:localsend_app/model/persistence/pending_friend_request.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Outgoing friend requests still waiting for an answer.
///
/// Persisted so a reply arriving after an app restart can still be matched to
/// the request that caused it.
final pendingFriendRequestsProvider = ReduxProvider<PendingFriendRequestsService, List<PendingFriendRequest>>((ref) {
  return PendingFriendRequestsService(ref.read(persistenceProvider));
});

class PendingFriendRequestsService extends ReduxNotifier<List<PendingFriendRequest>> {
  final PersistenceService _persistence;

  PendingFriendRequestsService(this._persistence);

  @override
  List<PendingFriendRequest> init() => _persistence.getPendingFriendRequests();
}

/// How long an unanswered friend request keeps blocking a new attempt.
///
/// Without an expiry a request whose answer never arrived (peer offline, app
/// killed mid-handshake) would hide the add button forever, with no way to
/// recover from the UI.
const pendingFriendRequestTimeout = Duration(minutes: 5);

extension PendingFriendRequestsExt on Iterable<PendingFriendRequest> {
  /// Requests still young enough to block a retry.
  ///
  /// Only used to decide whether to offer the button again: a late answer is
  /// still matched against the full list, so nothing is lost by expiring here.
  Iterable<PendingFriendRequest> get active {
    final now = DateTime.now().toUtc();
    return where((e) => now.difference(e.createdAt) < pendingFriendRequestTimeout);
  }

  PendingFriendRequest? findByRequestId(String requestId) {
    return firstWhereOrNull((e) => e.requestId == requestId);
  }

  /// The outstanding request for a peer. There is at most one, since
  /// [AddPendingFriendRequestAction] replaces any earlier one.
  PendingFriendRequest? findByFingerprint(String fingerprint) {
    return firstWhereOrNull((e) => e.fingerprint.toUpperCase() == fingerprint.toUpperCase());
  }

  bool hasPendingFor(String fingerprint) {
    return any((e) => e.fingerprint == fingerprint);
  }
}

class AddPendingFriendRequestAction extends AsyncReduxAction<PendingFriendRequestsService, List<PendingFriendRequest>> {
  final PendingFriendRequest request;

  AddPendingFriendRequestAction(this.request);

  @override
  Future<List<PendingFriendRequest>> reduce() async {
    // Only one outstanding request per peer; a repeated tap replaces the old one.
    final updated = List<PendingFriendRequest>.unmodifiable([
      ...state.where((e) => e.fingerprint != request.fingerprint),
      request,
    ]);
    await notifier._persistence.setPendingFriendRequests(updated);
    return updated;
  }
}

class RemovePendingFriendRequestAction extends AsyncReduxAction<PendingFriendRequestsService, List<PendingFriendRequest>> {
  final String requestId;

  RemovePendingFriendRequestAction({required this.requestId});

  @override
  Future<List<PendingFriendRequest>> reduce() async {
    final updated = List<PendingFriendRequest>.unmodifiable(state.where((e) => e.requestId != requestId));
    if (updated.length == state.length) {
      return state;
    }
    await notifier._persistence.setPendingFriendRequests(updated);
    return updated;
  }
}
