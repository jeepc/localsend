import 'package:flutter/material.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/pages/tabs/chat_tab_vm.dart';
import 'package:localsend_app/provider/chat/presence_provider.dart';
import 'package:localsend_app/widget/chat/chat_divider.dart';
import 'package:localsend_app/widget/chat/friend_avatar.dart';
import 'package:localsend_app/widget/chat/presence_refresh_button.dart';

/// Mobile friend list: a horizontally scrollable strip pinned above the
/// conversation, since a sidebar would eat most of a phone screen.
class FriendStrip extends StatelessWidget {
  final ChatTabVm vm;
  final ValueChanged<Friend> onSelect;
  final ValueChanged<Friend> onEdit;

  const FriendStrip({
    required this.vm,
    required this.onSelect,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selected = vm.selectedFriend;

    return Container(
      height: 96,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: chatDividerColor(context))),
      ),
      child: Row(
        children: [
          // Pinned outside the scroll view: a refresh the user has to scroll to
          // find is no use when the dots look wrong.
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: PresenceRefreshButton(refreshing: vm.refreshing, onPressed: vm.onRefresh),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: vm.groups.length,
              separatorBuilder: (_, _) => const ChatVerticalDivider(width: 17, indent: 8, endIndent: 8),
              itemBuilder: (context, groupIndex) {
                final group = vm.groups[groupIndex];
                return Row(
                  children: [
                    for (final friend in group.friends)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _StripEntry(
                          friend: friend,
                          status: vm.statusOf(friend),
                          dimmed: !group.isCurrent,
                          selected: selected?.fingerprint == friend.fingerprint,
                          onTap: () => onSelect(friend),
                          onLongPress: () => onEdit(friend),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StripEntry extends StatelessWidget {
  final Friend friend;
  final PresenceStatus status;
  final bool dimmed;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StripEntry({
    required this.friend,
    required this.status,
    required this.dimmed,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: FriendAvatar(friend: friend, status: status, radius: 20),
              ),
              const SizedBox(height: 4),
              Text(
                friend.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
