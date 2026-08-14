import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/pages/tabs/chat_tab_vm.dart';
import 'package:localsend_app/provider/chat/presence_provider.dart';
import 'package:localsend_app/widget/chat/friend_avatar.dart';
import 'package:localsend_app/widget/chat/presence_refresh_button.dart';

/// Desktop friend list: a searchable column sectioned by LAN group, with the
/// network the user is on right now at the top.
class FriendSidebar extends StatefulWidget {
  final ChatTabVm vm;
  final ValueChanged<Friend> onSelect;
  final ValueChanged<Friend> onEdit;

  const FriendSidebar({
    required this.vm,
    required this.onSelect,
    required this.onEdit,
    super.key,
  });

  @override
  State<FriendSidebar> createState() => _FriendSidebarState();
}

class _FriendSidebarState extends State<FriendSidebar> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.vm.selectedFriend;
    final groups = filterFriendGroups(widget.vm.groups, _query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: t.chatTab.search,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(width: 4),
              PresenceRefreshButton(refreshing: widget.vm.refreshing, onPressed: widget.vm.onRefresh),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          group.label,
                          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.isCurrent) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.wifi, size: 12, color: theme.colorScheme.primary),
                      ],
                    ],
                  ),
                ),
                for (final friend in group.friends)
                  _FriendTile(
                    friend: friend,
                    status: widget.vm.statusOf(friend),
                    // Friends on another LAN cannot be reached from here; dimming
                    // them is honest about that instead of failing on send.
                    dimmed: !group.isCurrent,
                    selected: selected?.fingerprint == friend.fingerprint,
                    onTap: () => widget.onSelect(friend),
                    onEdit: () => widget.onEdit(friend),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Keeps only the friends matching [query], dropping groups that end up empty.
List<FriendGroup> filterFriendGroups(List<FriendGroup> groups, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return groups;
  }
  final result = <FriendGroup>[];
  for (final group in groups) {
    final matches = group.friends.where((f) => f.displayName.toLowerCase().contains(trimmed)).toList();
    if (matches.isNotEmpty) {
      result.add(
        FriendGroup(
          networkId: group.networkId,
          label: group.label,
          isCurrent: group.isCurrent,
          friends: matches,
        ),
      );
    }
  }
  return result;
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  final PresenceStatus status;
  final bool dimmed;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _FriendTile({
    required this.friend,
    required this.status,
    required this.dimmed,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: theme.colorScheme.secondaryContainer,
        leading: FriendAvatar(friend: friend, status: status, radius: 18),
        title: Text(friend.displayName, overflow: TextOverflow.ellipsis),
        onTap: onTap,
        onLongPress: onEdit,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, size: 18),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
