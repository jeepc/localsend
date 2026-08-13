import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:routerino/routerino.dart';

/// Asks the user whether an incoming friend request should be accepted.
///
/// Pops true (accept), false (decline) or null when dismissed, which is
/// treated as a decline by the caller.
class FriendRequestDialog extends StatelessWidget {
  final String alias;

  const FriendRequestDialog({required this.alias, super.key});

  static Future<bool?> open(BuildContext context, {required String alias}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => FriendRequestDialog(alias: alias),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.dialogs.friendRequest.title),
      content: Text(t.dialogs.friendRequest.content(alias: alias)),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(t.general.decline),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(true),
          child: Text(t.general.accept),
        ),
      ],
    );
  }
}
