import 'package:localsend_app/model/persistence/chat_message.dart';
import 'package:localsend_app/provider/chat/chat_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:test/test.dart';

import '../../mocks.mocks.dart';

const _fingerprint = 'AA';

void main() {
  late MockPersistenceService persistenceService;

  setUp(() {
    persistenceService = MockPersistenceService();
  });

  test('Should record the files of one transfer as one message', () async {
    final service = ReduxNotifier.test(redux: ChatService(persistenceService));

    await service.dispatchAsync(
      AppendFilesAction(
        fingerprint: _fingerprint,
        outgoing: true,
        files: [
          _file('a.png', 100, isImage: true),
          _file('b.png', 200, isImage: true),
          _file('c.png', 300, isImage: true),
        ],
        status: null,
        messageId: 'm1',
      ),
    );

    final messages = service.state[_fingerprint]!;
    expect(messages.length, 1);
    expect(messages.single.fileName, 'a.png');
    expect(messages.single.fileCount, 3);
    expect(messages.single.fileSize, 600);
    expect(messages.single.filePaths, ['a.png.path', 'b.png.path', 'c.png.path']);
    expect(messages.single.type, ChatMessageType.image);
    expect(messages.single.status, ChatMessageStatus.sent);
  });

  test('Should fold files reported one by one into the message of their transfer', () async {
    // The receiving side learns about one file at a time.
    final service = ReduxNotifier.test(redux: ChatService(persistenceService));

    for (final file in [_file('a.png', 100, isImage: true), _file('b.txt', 200, isImage: false)]) {
      await service.dispatchAsync(
        AppendFilesAction(
          fingerprint: _fingerprint,
          outgoing: false,
          files: [file],
          status: null,
          messageId: 'm1',
        ),
      );
    }

    final messages = service.state[_fingerprint]!;
    expect(messages.length, 1);
    expect(messages.single.fileName, 'a.png');
    expect(messages.single.fileCount, 2);
    expect(messages.single.fileSize, 300);
    expect(messages.single.filePaths, ['a.png.path', 'b.txt.path']);
    // A batch that is not all images is not an image message.
    expect(messages.single.type, ChatMessageType.file);
  });

  test('Should append a message per transfer', () async {
    final service = ReduxNotifier.test(redux: ChatService(persistenceService));

    for (final messageId in ['m1', 'm2']) {
      await service.dispatchAsync(
        AppendFilesAction(
          fingerprint: _fingerprint,
          outgoing: true,
          files: [_file('a.png', 100, isImage: true)],
          status: null,
          messageId: messageId,
        ),
      );
    }

    expect(service.state[_fingerprint]!.map((e) => e.id), ['m1', 'm2']);
  });

  test('Should move the message of a transfer to the reported status', () async {
    final service = ReduxNotifier.test(redux: ChatService(persistenceService));

    await service.dispatchAsync(
      AppendFilesAction(
        fingerprint: _fingerprint,
        outgoing: true,
        files: [_file('a.png', 100, isImage: true)],
        status: ChatMessageStatus.sending,
        messageId: 'm1',
      ),
    );
    await service.dispatchAsync(
      AppendFilesAction(
        fingerprint: _fingerprint,
        outgoing: true,
        files: [_file('b.png', 200, isImage: true)],
        status: ChatMessageStatus.failed,
        messageId: 'm1',
      ),
    );

    expect(service.state[_fingerprint]!.single.status, ChatMessageStatus.failed);
  });

  test('Should settle an optimistic bubble in place instead of appending a second one', () async {
    // Outgoing files are shown as sending the moment the session starts; the
    // outcome moves that very bubble.
    final service = ReduxNotifier.test(redux: ChatService(persistenceService));

    await service.dispatchAsync(
      AppendFilesAction(
        fingerprint: _fingerprint,
        outgoing: true,
        files: [_file('a.png', 100, isImage: true), _file('b.png', 200, isImage: true)],
        status: ChatMessageStatus.sending,
        messageId: 'm1',
      ),
    );
    expect(service.state[_fingerprint]!.single.status, ChatMessageStatus.sending);

    await service.dispatchAsync(
      UpdateMessageStatusAction(
        fingerprint: _fingerprint,
        messageId: 'm1',
        status: ChatMessageStatus.failed,
      ),
    );

    final messages = service.state[_fingerprint]!;
    expect(messages.length, 1);
    expect(messages.single.status, ChatMessageStatus.failed);
    // The files of the bubble survive the status change, so a retry still knows
    // what to resend.
    expect(messages.single.fileCount, 2);
    expect(messages.single.filePaths, ['a.png.path', 'b.png.path']);
  });

  test('Should ignore a status update for a message that is no longer there', () async {
    // A conversation can be cleared while its transfer is still running.
    final service = ReduxNotifier.test(redux: ChatService(persistenceService));

    await service.dispatchAsync(
      UpdateMessageStatusAction(
        fingerprint: _fingerprint,
        messageId: 'gone',
        status: ChatMessageStatus.sent,
      ),
    );

    expect(service.state[_fingerprint], anyOf(isNull, isEmpty));
  });
}

ChatFile _file(String fileName, int fileSize, {required bool isImage}) {
  return (fileName: fileName, fileSize: fileSize, filePath: '$fileName.path', isImage: isImage);
}
