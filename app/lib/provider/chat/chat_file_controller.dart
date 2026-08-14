import 'dart:io';

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/widgets.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/provider/chat/chat_controller.dart';
import 'package:localsend_app/provider/chat/chat_provider.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/ui/snackbar.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// Collects files into the send tab's staging area with [collect], then sends
/// whatever landed there straight to a friend. Returns whether the caller can
/// consider the files handled.
///
/// The pickers and the drop handler all write into
/// [selectedSendingFilesProvider], which is the send tab's staging area.
/// Attaching something to a chat is a different intent, so the previous staging
/// is snapshotted and restored: sending a photo to a friend must not silently
/// discard files the user lined up on the send tab.
///
/// [SetSelectionAction] rather than [ClearSelectionAction]: the latter also
/// purges the file cache, which would invalidate the very files being borrowed.
///
/// An unreachable friend always leaves an undelivered bubble, so the attempt is
/// visible in the conversation and can be retried from there.
/// [handlesUnreachable] only decides whether that is the whole answer: the
/// picker was opened on purpose, so the bubble is enough (true), while dropped
/// files are additionally handed back to the caller (false) to be staged on the
/// send tab.
Future<bool> _collectAndSend(
  Ref ref,
  String fingerprint,
  Future<void> Function() collect, {
  required bool handlesUnreachable,
}) async {
  final target = ref.resolveChatTarget(fingerprint);

  final previousSelection = List<CrossFile>.from(ref.read(selectedSendingFilesProvider));
  ref.redux(selectedSendingFilesProvider).dispatch(SetSelectionAction(const []));

  List<CrossFile> collected;
  try {
    await collect();
    collected = List<CrossFile>.from(ref.read(selectedSendingFilesProvider));
  } finally {
    ref.redux(selectedSendingFilesProvider).dispatch(SetSelectionAction(previousSelection));
  }

  if (collected.isEmpty) {
    return true;
  }

  if (target == null) {
    // No address to even try, so this never becomes a session. The files still
    // show up as undelivered instead of disappearing.
    await ref.global.dispatchAsync(
      RecordFilesMessageAction(
        fingerprint: fingerprint,
        outgoing: true,
        files: [
          for (final file in collected) (fileName: file.name, fileSize: file.size, filePath: file.path, isImage: file.fileType == FileType.image),
        ],
        status: ChatMessageStatus.failed,
      ),
    );
    return handlesUnreachable;
  }

  // background: true keeps the transfer out of the foreground pages. The bubble
  // is created by the send provider as soon as the session starts.
  await ref.notifier(sendProvider).startSession(target: target, files: collected, background: true);
  return true;
}

/// Picks files with the regular picker and sends them to a friend.
class SendChatFilesAction extends AsyncGlobalAction {
  final String fingerprint;
  final FilePickerOption option;
  final BuildContext context;

  SendChatFilesAction({
    required this.fingerprint,
    required this.option,
    required this.context,
  });

  @override
  Future<void> reduce() async {
    await _collectAndSend(
      ref,
      fingerprint,
      () => ref.global.dispatchAsync(PickFileAction(option: option, context: context)),
      handlesUnreachable: true,
    );
  }
}

/// Sends files dropped onto an open conversation to that friend.
///
/// Returns false when the friend cannot be reached: the conversation keeps an
/// undelivered bubble, and the caller still falls back to the normal drop
/// behaviour so the files also end up somewhere the user can act on them.
class SendChatDroppedFilesAction extends AsyncGlobalActionWithResult<bool> {
  final String fingerprint;
  final List<XFile> files;

  SendChatDroppedFilesAction({required this.fingerprint, required this.files});

  @override
  Future<bool> reduce() async {
    return _collectAndSend(
      ref,
      fingerprint,
      () async {
        if (files.length == 1 && Directory(files.first.path).existsSync()) {
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(files.first.path));
        } else {
          await ref
              .redux(selectedSendingFilesProvider)
              .dispatchAsync(
                AddFilesAction(
                  files: files,
                  converter: CrossFileConverters.convertXFile,
                ),
              );
        }
      },
      handlesUnreachable: false,
    );
  }
}

/// Retries a file message that never made it to the peer.
///
/// The bubble is reused rather than duplicated: [SendNotifier.startSession]
/// carries its id and writes the outcome back onto it.
class ResendChatFileMessageAction extends AsyncGlobalAction {
  final ChatMessage message;

  ResendChatFileMessageAction(this.message);

  @override
  Future<void> reduce() async {
    Future<void> markFailed() => ref
        .redux(chatProvider)
        .dispatchAsync(
          UpdateMessageStatusAction(
            fingerprint: message.peerFingerprint,
            messageId: message.id,
            status: ChatMessageStatus.failed,
          ),
        );

    // All or nothing: a bubble that stands for several files must not end up
    // claiming to be delivered when only some of them were still around.
    final paths = message.filePaths;
    if (paths.length != message.fileCount || paths.any((path) => !File(path).existsSync())) {
      // A file was moved or deleted since it was picked; there is nothing left to send.
      await markFailed();
      // The global navigator context, which outlives the awaits above.
      // ignore: use_build_context_synchronously
      Routerino.context.showSnackBar(t.chatTab.fileMissing);
      return;
    }

    final target = ref.resolveChatTarget(message.peerFingerprint);
    if (target == null) {
      await markFailed();
      return;
    }

    await ref
        .redux(chatProvider)
        .dispatchAsync(
          UpdateMessageStatusAction(
            fingerprint: message.peerFingerprint,
            messageId: message.id,
            status: ChatMessageStatus.sending,
          ),
        );

    final files = [
      for (final path in paths) await CrossFileConverters.convertFile(File(path)),
    ];
    await ref.notifier(sendProvider).startSession(target: target, files: files, background: true, chatMessageId: message.id);
  }
}
