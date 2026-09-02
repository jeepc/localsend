import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/model/persistence/known_network.dart';
import 'package:localsend_app/provider/chat/chat_controller.dart';
import 'package:localsend_app/provider/chat/friends_provider.dart';
import 'package:localsend_app/provider/known_networks_provider.dart';
import 'package:localsend_app/widget/dialogs/friend_delete_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// Lets the user rename a friend, move them to another LAN group and correct
/// the address chat falls back to.
class FriendEditDialog extends StatefulWidget {
  final Friend friend;

  const FriendEditDialog({required this.friend, super.key});

  static Future<void> open(BuildContext context, Friend friend) {
    return showDialog(
      context: context,
      builder: (_) => FriendEditDialog(friend: friend),
    );
  }

  @override
  State<FriendEditDialog> createState() => _FriendEditDialogState();
}

class _FriendEditDialogState extends State<FriendEditDialog> with Refena {
  late final TextEditingController _aliasController;
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  late String? _networkId;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.friend.displayName);
    _ipController = TextEditingController(text: widget.friend.lastIp ?? '');
    _portController = TextEditingController(text: widget.friend.lastPort.toString());
    _networkId = widget.friend.networkId;
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final trimmed = _aliasController.text.trim();
    final ip = _ipController.text.trim();
    // Garbage in the port field must not silently turn into port 0 and break a
    // friend that was reachable; keep what was there.
    final port = int.tryParse(_portController.text.trim());
    await ref
        .redux(friendsProvider)
        .dispatchAsync(
          UpdateFriendAction(
            widget.friend.copyWith(
              // An empty field means "no nickname", falling back to the alias
              // the device reports.
              customAlias: trimmed.isEmpty || trimmed == widget.friend.alias ? null : trimmed,
              networkId: _networkId,
              lastIp: ip.isEmpty ? null : ip,
              lastPort: port != null && port > 0 && port <= 65535 ? port : widget.friend.lastPort,
            ),
          ),
        );
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await FriendDeleteDialog.open(context, widget.friend);
    if (confirmed != true) {
      return;
    }
    // Two-sided: also tells the peer, so they do not keep a friendship that no
    // longer exists on this side.
    await ref.global.dispatchAsync(UnfriendAction(widget.friend.fingerprint));
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final networks = ref.watch(knownNetworksProvider);

    return AlertDialog(
      title: Text(t.dialogs.friendEdit.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _aliasController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.dialogs.friendEdit.alias),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String?>(
              initialValue: _networkId,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.dialogs.friendEdit.network),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(t.dialogs.friendEdit.noGroup),
                ),
                ...networks.map(
                  (KnownNetwork network) => DropdownMenuItem<String?>(
                    value: network.id,
                    child: Text(network.label, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _networkId = value),
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _ipController,
                    decoration: InputDecoration(labelText: t.dialogs.friendEdit.ip),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: t.dialogs.friendEdit.port),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              t.dialogs.friendEdit.addressHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _delete,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(t.general.delete),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _save,
          child: Text(t.general.save),
        ),
      ],
    );
  }
}
