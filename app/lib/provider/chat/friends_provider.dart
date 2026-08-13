import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Devices the user has a mutual, accepted relationship with.
///
/// Kept separate from `favoritesProvider` on purpose: favorites are quick-send
/// targets the user picked unilaterally, friends are chat partners that
/// required the peer to agree.
final friendsProvider = ReduxProvider<FriendsService, List<Friend>>((ref) {
  return FriendsService(ref.read(persistenceProvider));
});

class FriendsService extends ReduxNotifier<List<Friend>> {
  final PersistenceService _persistence;

  FriendsService(this._persistence);

  @override
  List<Friend> init() => _persistence.getFriends();
}

class AddFriendAction extends AsyncReduxAction<FriendsService, List<Friend>> {
  final Friend friend;

  AddFriendAction(this.friend);

  @override
  Future<List<Friend>> reduce() async {
    final existing = state.indexWhere((e) => e.fingerprint == friend.fingerprint);
    if (existing != -1) {
      // Already a friend: refresh the address and group rather than duplicating.
      final updated = List<Friend>.unmodifiable(
        <Friend>[...state]..replaceRange(existing, existing + 1, [
          state[existing].copyWith(
            alias: friend.alias,
            lastIp: friend.lastIp,
            lastPort: friend.lastPort,
            networkId: friend.networkId ?? state[existing].networkId,
          ),
        ]),
      );
      await notifier._persistence.setFriends(updated);
      return updated;
    }

    final updated = List<Friend>.unmodifiable([...state, friend]);
    await notifier._persistence.setFriends(updated);
    return updated;
  }
}

class UpdateFriendAction extends AsyncReduxAction<FriendsService, List<Friend>> {
  final Friend friend;

  UpdateFriendAction(this.friend);

  @override
  Future<List<Friend>> reduce() async {
    final index = state.indexWhere((e) => e.id == friend.id);
    if (index == -1) {
      await Future.microtask(() {});
      return state;
    }
    final updated = List<Friend>.unmodifiable(
      <Friend>[...state]..replaceRange(index, index + 1, [friend]),
    );
    await notifier._persistence.setFriends(updated);
    return updated;
  }
}

/// Removes a friend and drops the conversation stored under its fingerprint.
class RemoveFriendAction extends AsyncReduxAction<FriendsService, List<Friend>> {
  final String fingerprint;

  RemoveFriendAction({required this.fingerprint});

  @override
  Future<List<Friend>> reduce() async {
    final updated = List<Friend>.unmodifiable(state.where((e) => e.fingerprint != fingerprint));
    if (updated.length == state.length) {
      return state;
    }
    await notifier._persistence.setFriends(updated);
    await notifier._persistence.removeChatMessages(fingerprint);
    return updated;
  }
}
