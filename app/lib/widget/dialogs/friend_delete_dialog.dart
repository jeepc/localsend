import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:routerino/routerino.dart';

/// Confirms removing a friend, which also drops the conversation.
class FriendDeleteDialog extends StatelessWidget {
  final Friend friend;

  const FriendDeleteDialog(this.friend, {super.key});

  static Future<bool?> open(BuildContext context, Friend friend) {
    return showDialog<bool>(
      context: context,
      builder: (_) => FriendDeleteDialog(friend),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.dialogs.friendDelete.title),
      content: Text(t.dialogs.friendDelete.content(alias: friend.displayName)),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(t.general.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => context.pop(true),
          child: Text(t.general.delete),
        ),
      ],
    );
  }
}
