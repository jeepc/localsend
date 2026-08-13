import 'dart:convert';

import 'package:localsend_app/util/chat_envelope.dart';
import 'package:test/test.dart';

void main() {
  group('ChatTextEnvelope', () {
    test('should round trip', () {
      final original = ChatTextEnvelope(
        messageId: 'a1b2c3d4-0000-4000-8000-000000000001',
        timestamp: DateTime.utc(2026, 8, 13, 10, 30, 15),
        text: 'Hello there',
      );

      final parsed = ChatEnvelope.tryParse(original.fileName, original.preview);

      expect(parsed, isA<ChatTextEnvelope>());
      final textEnvelope = parsed as ChatTextEnvelope;
      expect(textEnvelope.messageId, original.messageId);
      expect(textEnvelope.timestamp, original.timestamp);
      expect(textEnvelope.text, original.text);
    });

    test('should keep the preview a plain string so stock LocalSend still shows it', () {
      final envelope = ChatTextEnvelope(
        messageId: 'id',
        timestamp: DateTime.utc(2026),
        text: 'no json here',
      );

      expect(envelope.preview, 'no json here');
      expect(envelope.fileName, endsWith('.txt'));
    });

    test('should preserve text containing underscores and newlines', () {
      final original = ChatTextEnvelope(
        messageId: 'some_id_with_underscores',
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        text: 'line one\nline_two_with_underscores',
      );

      final parsed = ChatEnvelope.tryParse(original.fileName, original.preview) as ChatTextEnvelope;

      expect(parsed.messageId, original.messageId);
      expect(parsed.text, original.text);
      expect(parsed.timestamp, original.timestamp);
    });
  });

  group('FriendRequestEnvelope', () {
    test('should round trip', () {
      const original = FriendRequestEnvelope(requestId: 'req-1', alias: 'Great Apple');

      final parsed = ChatEnvelope.tryParse(original.fileName, original.preview);

      expect(parsed, isA<FriendRequestEnvelope>());
      final request = parsed as FriendRequestEnvelope;
      expect(request.requestId, 'req-1');
      expect(request.alias, 'Great Apple');
    });

    test('should carry a json payload', () {
      const original = FriendRequestEnvelope(requestId: 'req-1', alias: 'Great Apple');

      expect(jsonDecode(original.preview), {'v': 1, 'type': 'friendRequest', 'alias': 'Great Apple'});
    });
  });

  group('FriendResponseEnvelope', () {
    test('should round trip an acceptance', () {
      const original = FriendResponseEnvelope(requestId: 'req-1', accepted: true, alias: 'zfb');

      final parsed = ChatEnvelope.tryParse(original.fileName, original.preview) as FriendResponseEnvelope;

      expect(parsed.requestId, 'req-1');
      expect(parsed.accepted, true);
      expect(parsed.alias, 'zfb');
    });

    test('should round trip a rejection', () {
      const original = FriendResponseEnvelope(requestId: 'req-2', accepted: false, alias: 'zfb');

      final parsed = ChatEnvelope.tryParse(original.fileName, original.preview) as FriendResponseEnvelope;

      expect(parsed.accepted, false);
    });
  });

  group('UnfriendEnvelope', () {
    test('should round trip', () {
      const original = UnfriendEnvelope(id: 'abc-1');

      final parsed = ChatEnvelope.tryParse(original.fileName, original.preview);

      expect(parsed, isA<UnfriendEnvelope>());
      expect((parsed as UnfriendEnvelope).id, 'abc-1');
    });

    test('should not be confused with a friend request', () {
      const request = FriendRequestEnvelope(requestId: 'abc-1', alias: 'a');
      const unfriend = UnfriendEnvelope(id: 'abc-1');

      expect(unfriend.fileName, isNot(request.fileName));
      expect(ChatEnvelope.tryParse(unfriend.fileName, unfriend.preview), isA<UnfriendEnvelope>());
      expect(ChatEnvelope.tryParse(request.fileName, request.preview), isA<FriendRequestEnvelope>());
    });
  });

  group('tryParse', () {
    test('should ignore a regular file name', () {
      expect(ChatEnvelope.tryParse('holiday.jpg', null), isNull);
      expect(ChatEnvelope.tryParse('4f0e1b8e-1234.txt', 'a normal message'), isNull);
    });

    test('should ignore an unknown envelope type', () {
      expect(ChatEnvelope.tryParse('${chatEnvelopePrefix}whatever_123.txt', '{}'), isNull);
    });

    test('should ignore a malformed payload', () {
      expect(ChatEnvelope.tryParse('${chatEnvelopePrefix}freq_req-1.txt', 'not json'), isNull);
      expect(ChatEnvelope.tryParse('${chatEnvelopePrefix}msg_id_notanumber.txt', 'hi'), isNull);
      expect(ChatEnvelope.tryParse('${chatEnvelopePrefix}msg_id_123.txt', null), isNull);
    });
  });
}
