import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:routerino/routerino.dart';

/// Lists the files behind one chat message, so a single one of them can be
/// opened. Only shown for messages that stand for more than one file.
class ChatFilesDialog extends StatelessWidget {
  final String title;
  final List<String> filePaths;

  const ChatFilesDialog({
    required this.title,
    required this.filePaths,
    super.key,
  });

  /// Returns the picked path, or null when the dialog was dismissed.
  static Future<String?> open(BuildContext context, {required String title, required List<String> filePaths}) async {
    return await showDialog<String>(
      context: context,
      builder: (_) => ChatFilesDialog(title: title, filePaths: filePaths),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: [
        for (final filePath in filePaths)
          SimpleDialogOption(
            onPressed: () => context.pop(filePath),
            child: Text(path.basename(filePath), overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}
