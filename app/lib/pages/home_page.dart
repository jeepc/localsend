import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/tabs/chat_tab.dart';
import 'package:localsend_app/pages/tabs/receive_tab.dart';
import 'package:localsend_app/pages/tabs/send_tab.dart';
import 'package:localsend_app/pages/tabs/settings_tab.dart';
import 'package:localsend_app/provider/chat/chat_controller.dart';
import 'package:localsend_app/provider/chat/chat_drop_provider.dart';
import 'package:localsend_app/provider/chat/chat_file_controller.dart';
import 'package:localsend_app/provider/chat/friends_provider.dart';
import 'package:localsend_app/provider/chat/selected_friend_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/friends.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/widget/chat/friend_drop_zone.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// The order of this enum is load-bearing: it drives both the navigation
/// destinations and the index into [PageView.children] below, which must be
/// kept in the same order.
enum HomeTab {
  chat(Icons.chat_bubble),
  receive(Icons.wifi),
  send(Icons.send),
  settings(Icons.settings)
  ;

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.chat:
        return t.chatTab.title;
      case HomeTab.receive:
        return t.receiveTab.title;
      case HomeTab.send:
        return t.sendTab.title;
      case HomeTab.settings:
        return t.settingsTab.title;
    }
  }
}

class HomePage extends StatefulWidget {
  final HomeTab initialTab;

  /// It is important for the initializing step
  /// because the first init clears the cache
  final bool appStart;

  const HomePage({
    required this.initialTab,
    required this.appStart,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  bool _dragAndDropIndicator = false;

  /// The friend list row the drag is currently over.
  ///
  /// Only a fallback for the drop itself, which hit-tests the drop position:
  /// the plugin reports the drag as exited right before it reports it as done,
  /// so this is deliberately not cleared there — the next drag resets it.
  String? _hoveredFingerprint;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) async {
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab));
      await postInit(context, ref, widget.appStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context); // rebuild on locale change
    final vm = context.watch(homePageControllerProvider);

    return DropTarget(
      onDragEntered: (_) {
        setState(() {
          _dragAndDropIndicator = true;
        });
        _hoveredFingerprint = null;
        if (vm.currentTab == HomeTab.chat) {
          ref.notifier(chatDropProvider).hover(null);
        }
      },
      onDragUpdated: (details) {
        if (vm.currentTab != HomeTab.chat) {
          return;
        }
        final fingerprint = friendFingerprintAt(context, details.globalPosition);
        if (fingerprint != _hoveredFingerprint) {
          _hoveredFingerprint = fingerprint;
          ref.notifier(chatDropProvider).hover(fingerprint);
        }
      },
      onDragExited: (_) {
        setState(() {
          _dragAndDropIndicator = false;
        });
        ref.notifier(chatDropProvider).stop();
      },
      onDragDone: (event) async {
        final droppedOn = vm.currentTab == HomeTab.chat ? (friendFingerprintAt(context, event.globalPosition) ?? _hoveredFingerprint) : null;
        _hoveredFingerprint = null;
        ref.notifier(chatDropProvider).stop();

        if (droppedOn != null && ref.read(friendsProvider).containsFingerprint(droppedOn)) {
          // A row in the friend list names its own recipient, so this wins over
          // whichever conversation happens to be open. Opening it as well puts
          // the transfer where the user can watch it — and retry it, should the
          // friend be unreachable.
          ref.openConversation(droppedOn);
          await ref.global.dispatchAsync(
            SendChatDroppedFilesAction(fingerprint: droppedOn, files: event.files),
          );
          return;
        }

        // Dropping onto an open conversation means "send this to them", not
        // "stage this for some device I have yet to pick".
        final selectedFriend = ref.read(selectedFriendProvider);
        if (vm.currentTab == HomeTab.chat && selectedFriend != null && ref.read(friendsProvider).containsFingerprint(selectedFriend)) {
          final handled = await ref.global.dispatchAsync(
            SendChatDroppedFilesAction(fingerprint: selectedFriend, files: event.files),
          );
          if (handled) {
            return;
          }
          // The friend is not reachable. The conversation already shows the
          // attempt as undelivered; fall through so the files still end up
          // somewhere the user can act on them.
        }

        // the drop may contain a mix of files and directories
        final droppedDirectories = event.files.where((file) => Directory(file.path).existsSync()).toList();
        final droppedFiles = event.files.where((file) => !Directory(file.path).existsSync()).toList();

        for (final directory in droppedDirectories) {
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(directory.path));
        }

        if (droppedFiles.isNotEmpty) {
          await ref
              .redux(selectedSendingFilesProvider)
              .dispatchAsync(
                AddFilesAction(
                  files: droppedFiles,
                  converter: CrossFileConverters.convertXFile,
                ),
              );
        }
        vm.changeTab(HomeTab.send);
      },
      child: ResponsiveBuilder(
        builder: (sizingInformation) {
          return Scaffold(
            body: Row(
              children: [
                if (!sizingInformation.isMobile)
                  NavigationRail(
                    selectedIndex: vm.currentTab.index,
                    onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                    extended: sizingInformation.isDesktop,
                    minExtendedWidth: 160,
                    backgroundColor: Theme.of(context).cardColorWithElevation,
                    leading: sizingInformation.isDesktop
                        ? const Column(
                            children: [
                              SizedBox(height: 20),
                              // The rail is only 160 wide, so let the title shrink instead of overflowing.
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'LocalSend',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          )
                        : null,
                    destinations: HomeTab.values.map((tab) {
                      return NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.label),
                      );
                    }).toList(),
                  ),
                Expanded(
                  child: SafeArea(
                    left: sizingInformation.isMobile,
                    child: Stack(
                      children: [
                        PageView(
                          controller: vm.controller,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            ChatTab(),
                            ReceiveTab(),
                            SendTab(),
                            SettingsTab(),
                          ],
                        ),
                        // The chat tab draws its own hint over the conversation
                        // only: covering the friend list would hide the very
                        // rows the drag can be aimed at.
                        if (_dragAndDropIndicator && vm.currentTab != HomeTab.chat)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.file_download, size: 128),
                                const SizedBox(height: 30),
                                Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleLarge),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: sizingInformation.isMobile
                ? NavigationBar(
                    selectedIndex: vm.currentTab.index,
                    onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                    destinations: HomeTab.values.map((tab) {
                      return NavigationDestination(icon: Icon(tab.icon), label: tab.label);
                    }).toList(),
                  )
                : null,
          );
        },
      ),
    );
  }
}
