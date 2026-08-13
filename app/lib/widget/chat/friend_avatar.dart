import 'package:flutter/material.dart';
import 'package:localsend_app/model/persistence/friend.dart';
import 'package:localsend_app/provider/chat/presence_provider.dart';

/// Circular initial-letter avatar with an online indicator.
class FriendAvatar extends StatelessWidget {
  final Friend friend;
  final PresenceStatus status;
  final double radius;

  const FriendAvatar({
    required this.friend,
    required this.status,
    this.radius = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = friend.displayName;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontSize: radius * 0.8,
            ),
          ),
        ),
        // Offline draws nothing; "unknown" draws a hollow dot, so a friend
        // whose state is still being checked does not read as either.
        if (status != PresenceStatus.offline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: status == PresenceStatus.online ? Colors.green : theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: status == PresenceStatus.online ? theme.scaffoldBackgroundColor : theme.colorScheme.outline,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
