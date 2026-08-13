import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/device_bage.dart';
import 'package:localsend_app/widget/list_tile/custom_list_tile.dart';
import 'package:localsend_isolates/model/device.dart';

class DeviceListTile extends StatelessWidget {
  final Device device;
  final bool isFavorite;

  /// If not null, this name is used instead of [Device.alias].
  /// This is the case when the device is marked as favorite.
  final String? nameOverride;

  final String? info;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsTap;

  /// Sends a friend request. Null hides the button, which is the case when a
  /// request is still awaiting an answer.
  final VoidCallback? onAddFriendTap;

  /// Opens the conversation with this device. Takes the place of
  /// [onAddFriendTap] once the device is a friend, so the same spot always
  /// offers the next useful step instead of going blank.
  final VoidCallback? onChatTap;

  const DeviceListTile({
    required this.device,
    this.isFavorite = false,
    this.nameOverride,
    this.info,
    this.progress,
    this.onTap,
    this.onDetailsTap,
    this.onAddFriendTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Color.lerp(Theme.of(context).colorScheme.secondaryContainer, Colors.white, 0.3)!;
    return CustomListTile(
      icon: Icon(device.deviceType.icon, size: 46),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(nameOverride ?? device.alias, style: const TextStyle(fontSize: 20)),
          if (isFavorite) ...[
            const SizedBox(width: 5),
            Icon(Icons.check_circle, size: 16),
          ],
        ],
      ),
      trailing: onDetailsTap != null || onAddFriendTap != null || onChatTap != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A friend gets the conversation shortcut, everyone else the
                // invite. They never appear together.
                if (onChatTap != null)
                  IconButton(
                    tooltip: t.chatTab.openChat,
                    icon: Icon(Icons.forum, color: Theme.of(context).colorScheme.primary),
                    onPressed: onChatTap,
                  )
                else if (onAddFriendTap != null)
                  IconButton(
                    tooltip: t.dialogs.friendRequest.title,
                    icon: const Icon(Icons.person_add_alt),
                    onPressed: onAddFriendTap,
                  ),
                if (onDetailsTap != null)
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: onDetailsTap,
                  ),
              ],
            )
          : null,
      subTitle: Wrap(
        runSpacing: 10,
        spacing: 10,
        children: [
          if (info != null)
            Text(info!, style: const TextStyle(color: Colors.grey))
          else if (progress != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: CustomProgressBar(progress: progress!),
            )
          else ...[
            if (device.ip != null)
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: 'HTTP',
              )
            else
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: 'WebRTC',
              ),
            if (device.deviceModel != null)
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: device.deviceModel!,
              ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
