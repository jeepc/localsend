import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/provider/chat/chat_provider.dart';
import 'package:localsend_app/provider/chat/friends_provider.dart';
import 'package:localsend_app/provider/chat/presence_provider.dart';
import 'package:localsend_app/provider/chat/selected_friend_provider.dart';
import 'package:localsend_app/provider/known_networks_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network_identity_provider.dart';
import 'package:localsend_app/util/friends.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Friends that belong to one LAN, e.g. everyone met at the office.
class FriendGroup {
  /// Null for friends whose network could not be identified when they were added.
  final String? networkId;

  final String label;

  /// True for the network this device is on right now. Sorted to the top and
  /// the only group whose members can actually be reached.
  final bool isCurrent;

  final List<Friend> friends;

  const FriendGroup({
    required this.networkId,
    required this.label,
    required this.isCurrent,
    required this.friends,
  });
}

class ChatTabVm {
  final List<FriendGroup> groups;
  final int friendCount;
  final Friend? selectedFriend;
  final List<ChatMessage> messages;

  /// Reachability per friend fingerprint, as of the last heartbeat.
  final Map<String, PresenceStatus> presence;

  /// Whether a heartbeat round is in flight; spins the refresh button.
  final bool refreshing;

  final void Function() onRefresh;

  const ChatTabVm({
    required this.groups,
    required this.friendCount,
    required this.selectedFriend,
    required this.messages,
    required this.presence,
    required this.refreshing,
    required this.onRefresh,
  });

  PresenceStatus statusOf(Friend friend) => presence[friend.fingerprint] ?? PresenceStatus.unknown;

  bool isOnline(Friend friend) => statusOf(friend) == PresenceStatus.online;
}

final chatTabVmProvider = ViewProvider((ref) {
  final friends = ref.watch(friendsProvider);
  final networks = ref.watch(knownNetworksProvider);
  final identity = ref.watch(networkIdentityProvider);
  final selectedFingerprint = ref.watch(selectedFriendProvider);
  final conversations = ref.watch(chatProvider);
  final nearby = ref.watch(nearbyDevicesProvider);
  final presenceState = ref.watch(presenceProvider);

  final currentNetwork = networks.findMatch(identity);

  final groups = <FriendGroup>[];
  for (final network in networks) {
    final members = friends.where((f) => f.networkId == network.id).toList();
    if (members.isEmpty) {
      continue;
    }
    groups.add(
      FriendGroup(
        networkId: network.id,
        label: network.label,
        isCurrent: currentNetwork?.id == network.id,
        friends: members,
      ),
    );
  }

  // Friends whose network was unknown when they were added, plus any whose
  // group was deleted since.
  final knownIds = networks.map((e) => e.id).toSet();
  final ungrouped = friends.where((f) => f.networkId == null || !knownIds.contains(f.networkId)).toList();
  if (ungrouped.isNotEmpty) {
    groups.add(
      FriendGroup(
        networkId: null,
        label: t.chatTab.ungrouped,
        isCurrent: false,
        friends: ungrouped,
      ),
    );
  }

  // The network the user is on right now goes first; everything else is
  // alphabetical so the order does not jump around.
  groups.sort((a, b) {
    if (a.isCurrent != b.isCurrent) {
      return a.isCurrent ? -1 : 1;
    }
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });

  final selectedFriend = selectedFingerprint == null ? null : friends.findByFingerprint(selectedFingerprint);

  final signaling = nearby.signalingDevices.entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toSet();

  return ChatTabVm(
    groups: groups,
    friendCount: friends.length,
    selectedFriend: selectedFriend,
    messages: selectedFriend == null ? const [] : (conversations[selectedFriend.fingerprint] ?? const []),
    // A device is only stamped once it answered on a real address, so the
    // stamps alone decide this — no need to intersect with [devices], which the
    // send tab's scan button empties. The heartbeat's [tickAt] is the clock, so
    // this stays a pure function of the watched state and still re-evaluates
    // when a friend simply stops answering.
    presence: {
      for (final friend in friends)
        friend.fingerprint: presenceStatusOf(
          fingerprint: friend.fingerprint,
          lastSeen: nearby.lastSeen,
          signalingFingerprints: signaling,
          now: presenceState.tickAt,
          firstRoundDone: presenceState.lastRoundAt != null,
        ),
    },
    refreshing: presenceState.probing,
    onRefresh: () => ref.redux(presenceProvider).dispatch(PresenceRefreshAction()),
  );
});
