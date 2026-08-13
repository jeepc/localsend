import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/progress_page.dart';
import 'package:localsend_app/pages/send_page.dart';
import 'package:localsend_app/pages/tabs/send_tab.dart';
import 'package:localsend_app/pages/web_share_page.dart';
import 'package:localsend_app/provider/chat/chat_controller.dart';
import 'package:localsend_app/provider/chat/chat_provider.dart';
import 'package:localsend_app/provider/chat/friends_provider.dart';
import 'package:localsend_app/provider/chat/network_group_controller.dart';
import 'package:localsend_app/provider/chat/pending_friend_requests_provider.dart';
import 'package:localsend_app/provider/chat/selected_friend_provider.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/widget/dialogs/add_file_dialog.dart';
import 'package:localsend_app/widget/dialogs/address_input_dialog.dart';
import 'package:localsend_app/widget/dialogs/favorite_dialog.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/model/session_status.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class SendTabVm {
  final SendMode sendMode;
  final List<CrossFile> selectedFiles;
  final List<String> localIps;
  final Iterable<Device> nearbyDevices;
  final List<FavoriteDevice> favoriteDevices;
  final List<Friend> friends;

  /// Fingerprints with a *recent* friend request still awaiting an answer;
  /// their button is hidden so the user does not fire off duplicates. Stale
  /// ones are excluded, otherwise a handshake that never completed would hide
  /// the button forever.
  final Set<String> pendingFriendRequests;

  final Future<void> Function(BuildContext context) onTapAddress;
  final Future<void> Function(BuildContext context) onTapFavorite;
  final Future<void> Function(BuildContext context, SendMode mode) onTapSendMode;
  final Future<void> Function(BuildContext context, Device device) onTapDevice;
  final Future<void> Function(BuildContext context, Device device) onTapDeviceMultiSend;
  final Future<void> Function(BuildContext context, Device device) onTapAddFriend;
  final void Function(Device device) onTapChat;

  const SendTabVm({
    required this.sendMode,
    required this.selectedFiles,
    required this.localIps,
    required this.nearbyDevices,
    required this.favoriteDevices,
    required this.friends,
    required this.pendingFriendRequests,
    required this.onTapAddress,
    required this.onTapFavorite,
    required this.onTapSendMode,
    required this.onTapDevice,
    required this.onTapDeviceMultiSend,
    required this.onTapAddFriend,
    required this.onTapChat,
  });

  /// Whether an add-friend button should be offered for [device].
  bool canAddFriend(Device device) {
    return device.fingerprint.isNotEmpty && device.ip != null && !isFriend(device) && !pendingFriendRequests.contains(device.fingerprint);
  }

  /// Whether [device] is already a friend. Surfaced on the tile so the missing
  /// add button has a visible reason.
  bool isFriend(Device device) {
    return friends.any((f) => f.fingerprint == device.fingerprint);
  }
}

final sendTabVmProvider = ViewProvider((ref) {
  final sendMode = ref.watch(settingsProvider.select((s) => s.sendMode));
  final selectedFiles = ref.watch(selectedSendingFilesProvider);
  final localIps = ref.watch(localIpProvider).localIps;
  final nearbyDevices = ref.watch(nearbyDevicesProvider).allDevices.values;
  final favoriteDevices = ref.watch(favoritesProvider);
  final friends = ref.watch(friendsProvider);
  final pendingFriendRequests = ref.watch(pendingFriendRequestsProvider).active.map((e) => e.fingerprint).toSet();

  return SendTabVm(
    sendMode: sendMode,
    selectedFiles: selectedFiles,
    localIps: localIps,
    nearbyDevices: nearbyDevices,
    favoriteDevices: favoriteDevices,
    friends: friends,
    pendingFriendRequests: pendingFriendRequests,
    onTapAddress: (context) async {
      var files = ref.read(selectedSendingFilesProvider);
      if (files.isEmpty) {
        await AddFileDialog.open(
          context: context,
          options: pickerOptions,
        );
      }

      files = ref.read(selectedSendingFilesProvider);

      if (files.isEmpty || !context.mounted) {
        return;
      }
      final device = await showDialog<Device?>(
        context: context,
        builder: (_) => const AddressInputDialog(),
      );
      if (device != null && context.mounted) {
        await ref
            .notifier(sendProvider)
            .startSession(
              target: device,
              files: files,
              background: false,
            );
      }
    },
    onTapFavorite: (context) async {
      final device = await showDialog<Device?>(
        context: context,
        builder: (_) => const FavoritesDialog(),
      );
      if (device != null && context.mounted) {
        var files = ref.read(selectedSendingFilesProvider);
        if (files.isEmpty) {
          await AddFileDialog.open(
            context: context,
            options: pickerOptions,
          );
        }

        files = ref.read(selectedSendingFilesProvider);

        if (files.isEmpty) {
          return;
        }

        await ref
            .notifier(sendProvider)
            .startSession(
              target: device,
              files: files,
              background: false,
            );
      }
    },
    onTapSendMode: (context, mode) async {
      if (mode == SendMode.link) {
        var files = ref.read(selectedSendingFilesProvider);
        if (files.isEmpty) {
          await AddFileDialog.open(
            context: context,
            options: pickerOptions,
          );
        }

        files = ref.read(selectedSendingFilesProvider);

        if (files.isEmpty || !context.mounted) {
          return;
        }
        await context.push(() => WebSharePage(files: files));
        return;
      }

      await ref.notifier(settingsProvider).setSendMode(mode);
      if (mode != SendMode.multiple) {
        ref.notifier(sendProvider).clearAllSessions();
      }
    },
    onTapDevice: (context, device) async {
      var files = selectedFiles;
      if (files.isEmpty) {
        await AddFileDialog.open(
          context: context,
          options: pickerOptions,
        );
      }

      files = ref.read(selectedSendingFilesProvider);

      if (files.isEmpty) {
        return;
      }

      await ref
          .notifier(sendProvider)
          .startSession(
            target: device,
            files: files,
            background: false,
          );
    },
    onTapDeviceMultiSend: (context, device) async {
      final session = ref.read(sendProvider).values.firstWhereOrNull((s) => s.target.ip == device.ip);
      if (session != null) {
        if (session.status == SessionStatus.waiting) {
          ref.notifier(sendProvider).setBackground(session.sessionId, false);
          await context.push(
            () => SendPage(showAppBar: true, closeSessionOnClose: false, sessionId: session.sessionId),
            transition: RouterinoTransition.fade(),
          );
          // Only restore background mode if the user actually backed out.
          // When the receiver accepts, the provider replaces this page with the ProgressPage,
          // which also resolves this future; the ProgressPage then owns the background flag.
          if (ref.read(sendProvider)[session.sessionId]?.status == SessionStatus.waiting) {
            ref.notifier(sendProvider).setBackground(session.sessionId, true);
          }
          return;
        } else if (session.status == SessionStatus.sending || session.status == SessionStatus.finishedWithErrors) {
          ref.notifier(sendProvider).setBackground(session.sessionId, false);
          await context.push(() => ProgressPage(showAppBar: true, closeSessionOnClose: false, sessionId: session.sessionId));
          ref.notifier(sendProvider).setBackground(session.sessionId, true);
          return;
        }
      }

      var files = ref.read(selectedSendingFilesProvider);

      if (files.isEmpty) {
        await AddFileDialog.open(
          context: context,
          options: pickerOptions,
        );
      }

      files = ref.read(selectedSendingFilesProvider);

      if (files.isEmpty) {
        return;
      }

      if (session != null) {
        // close old session
        ref.notifier(sendProvider).closeSession(session.sessionId);
      }

      await ref
          .notifier(sendProvider)
          .startSession(
            target: device,
            files: files,
            background: true,
          );
    },
    onTapChat: (device) {
      // Open the conversation the shortcut promises, not just the tab.
      ref.notifier(selectedFriendProvider).select(device.fingerprint);
      ref.redux(chatProvider).dispatch(LoadConversationAction(device.fingerprint));
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(HomeTab.chat));
    },
    onTapAddFriend: (context, device) async {
      // Resolve the group first: it may ask the user to name this network, and
      // doing that before the request keeps the whole flow in one interaction.
      final networkId = await ref.global.dispatchAsync(EnsureCurrentNetworkGroupAction());
      final delivered = await ref.global.dispatchAsync(SendFriendRequestAction(device, networkId: networkId));

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            delivered ? t.dialogs.friendRequest.sent(alias: device.alias) : t.dialogs.friendRequest.failed(alias: device.alias),
          ),
        ),
      );
    },
  );
});

class SendTabInitAction extends AsyncGlobalAction {
  final BuildContext context;

  SendTabInitAction(this.context);

  @override
  Future<void> reduce() async {
    // Not "are there devices": the chat presence heartbeat also registers
    // devices, but only the friends it probes, so a filled list is no longer
    // proof that the network was swept.
    if (!ref.read(nearbyDevicesProvider).initialScanDone) {
      await dispatchAsync(StartSmartScan());
    }
  }
}
