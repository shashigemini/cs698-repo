import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';

void main() {
  group('ChatRepository (Mock)', () {
    late MockChatRepository repository;

    setUp(() {
      repository = MockChatRepository();
    });

    test(
      'sendQuery returns AnswerResult with mocked answer and conversationId',
      () async {
        final result = await repository.sendQuery(
          'What is the capital of France?',
        );

        expect(result, isA<AnswerResult>());
        expect(result.answer, contains('What is the capital of France?'));
        expect(result.conversationId, 'new-mock-conv-id');
        expect(result.citations.length, 1);
      },
    );

    test(
      'sendQuery with guestSessionId throws RateLimitException after limit',
      () async {
        // Send 2 successful queries (count goes to 1, then 2)
        for (var i = 0; i < 2; i++) {
          final result = await repository.sendQuery(
            'Query $i',
            guestSessionId: 'guest123',
          );
          expect(result.answer, isNotEmpty);
        }

        // 3rd query should throw (count=3, 3>=guestQueryLimit)
        expect(
          () async =>
              await repository.sendQuery('Query 3', guestSessionId: 'guest123'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('sendQuery throws NetworkError when simulated', () async {
      repository.setSimulateNetworkError(true);

      expect(
        () async => await repository.sendQuery('Test'),
        throwsA(isA<Exception>()),
      );
    });

    test('loadHistory returns mocked list of messages', () async {
      final history = await repository.loadHistory('existing-conv-id');

      expect(history, isA<List<Message>>());
      expect(history.length, 2);
      expect(history[0].sender, 'user');
      expect(history[1].sender, 'assistant');
    });
  });
}
