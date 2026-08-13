import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/tabs/chat_tab_vm.dart';
import 'package:localsend_app/provider/chat/chat_controller.dart';
import 'package:localsend_app/provider/chat/chat_file_controller.dart';
import 'package:localsend_app/provider/chat/chat_provider.dart';
import 'package:localsend_app/provider/chat/presence_provider.dart';
import 'package:localsend_app/provider/chat/selected_friend_provider.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/widget/chat/chat_divider.dart';
import 'package:localsend_app/widget/chat/chat_panel.dart';
import 'package:localsend_app/widget/chat/friend_sidebar.dart';
import 'package:localsend_app/widget/chat/friend_strip.dart';
import 'package:localsend_app/widget/dialogs/friend_edit_dialog.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Friends and their conversations.
///
/// Desktop puts the friend list in a left sidebar; on a phone that would eat
/// most of the screen, so the list becomes a horizontally scrollable strip
/// pinned above the conversation.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with Refena, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The tab is destroyed when the user leaves it (the PageView keeps no
    // pages around), so mounting and unmounting is exactly "the chat is on
    // screen" and the heartbeat can be tied to it.
    ensureRef((ref) => ref.redux(presenceProvider).dispatch(StartPresenceWatchAction()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.redux(presenceProvider).dispatch(StopPresenceWatchAction());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only paused and hidden mean the user cannot see the tab. Desktop reports
    // "inactive" whenever the window loses focus, which is not a reason to
    // stop, and minimising / going to tray is covered by [sleepProvider].
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        ref.redux(presenceProvider).dispatch(StopPresenceWatchAction());
        break;
      case AppLifecycleState.resumed:
        ref.redux(presenceProvider).dispatch(StartPresenceWatchAction());
        break;
      default:
        break;
    }
  }

  void _selectFriend(Friend friend) {
    ref.notifier(selectedFriendProvider).select(friend.fingerprint);
    // Conversations are lazily read from disk on first open.
    ref.redux(chatProvider).dispatch(LoadConversationAction(friend.fingerprint));
  }

  /// Opens the most recent conversation whenever nothing is selected: on app
  /// start, after the selected friend was unfriended, and when the very first
  /// friend is accepted while this tab is on screen. [ChatTabVm.selectedFriend]
  /// is null in all three cases — a fingerprint that no longer belongs to a
  /// friend does not resolve either — so one check covers them.
  ///
  /// The groups are sorted with the current network first and each group by
  /// recency, so the first entry is the last friend the user talked to among the
  /// reachable ones.
  void _autoSelectFirstFriend() {
    final vm = ref.read(chatTabVmProvider);
    if (vm.selectedFriend != null) {
      return;
    }
    final first = vm.groups.firstOrNull?.friends.firstOrNull;
    if (first != null) {
      _selectFriend(first);
    }
  }

  Future<void> _editFriend(Friend friend) async {
    await FriendEditDialog.open(context, friend);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(chatTabVmProvider);

    if (vm.friendCount == 0) {
      return const _NoFriends();
    }

    if (vm.selectedFriend == null) {
      // Selecting mutates two providers, which must not happen while this frame
      // is being built. Picking someone rebuilds with a selection, so this does
      // not fire again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _autoSelectFirstFriend();
        }
      });
    }

    final panel = vm.selectedFriend == null
        ? const _SelectFriendHint()
        : ChatPanel(
            key: ValueKey(vm.selectedFriend!.fingerprint),
            friend: vm.selectedFriend!,
            messages: vm.messages,
            status: vm.statusOf(vm.selectedFriend!),
            onSubmit: (text) async {
              await ref.global.dispatchAsync(
                SendChatTextAction(fingerprint: vm.selectedFriend!.fingerprint, text: text),
              );
            },
            onPickFiles: () async {
              await ref.global.dispatchAsync(
                SendChatFilesAction(
                  fingerprint: vm.selectedFriend!.fingerprint,
                  option: FilePickerOption.file,
                  context: context,
                ),
              );
            },
            onPickImages: () async {
              await ref.global.dispatchAsync(
                SendChatFilesAction(
                  fingerprint: vm.selectedFriend!.fingerprint,
                  option: FilePickerOption.media,
                  context: context,
                ),
              );
            },
            onResend: (message) async {
              await ref.global.dispatchAsync(
                message.type == ChatMessageType.text ? ResendChatMessageAction(message) : ResendChatFileMessageAction(message),
              );
            },
            onOpenFile: (ChatMessage message) async {
              if (message.filePath != null) {
                await openFile(context, message.type == ChatMessageType.image ? FileType.image : FileType.other, message.filePath!);
              }
            },
            onClearConversation: () async {
              await ref.redux(chatProvider).dispatchAsync(ClearConversationAction(vm.selectedFriend!.fingerprint));
            },
          );

    return ResponsiveBuilder(
      builder: (sizingInformation) {
        if (sizingInformation.isMobile) {
          return Column(
            children: [
              FriendStrip(vm: vm, onSelect: _selectFriend, onEdit: _editFriend),
              Expanded(child: panel),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(
              width: 260,
              child: FriendSidebar(vm: vm, onSelect: _selectFriend, onEdit: _editFriend),
            ),
            const ChatVerticalDivider(),
            Expanded(child: panel),
          ],
        );
      },
    );
  }
}

class _SelectFriendHint extends StatelessWidget {
  const _SelectFriendHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        t.chatTab.selectFriend,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _NoFriends extends StatelessWidget {
  const _NoFriends();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 96, color: theme.colorScheme.outline),
            const SizedBox(height: 20),
            Text(t.chatTab.noFriends.title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              t.chatTab.noFriends.description,
              style: TextStyle(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(t.sendTab.title),
              onPressed: () => context.redux(homePageControllerProvider).dispatch(ChangeTabAction(HomeTab.send)),
            ),
          ],
        ),
      ),
    );
  }
}
