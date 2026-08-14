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
}

ChatFile _file(String fileName, int fileSize, {required bool isImage}) {
  return (fileName: fileName, fileSize: fileSize, filePath: '$fileName.path', isImage: isImage);
}
