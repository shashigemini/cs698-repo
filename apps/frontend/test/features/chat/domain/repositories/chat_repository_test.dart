import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import '../../../../helpers/crypto_mocks.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('ChatRepository (Mock)', () {
    late MockChatRepository repository;
    late MockSessionKeyStore mockSessionKeys;

    setUp(() {
      mockSessionKeys = MockSessionKeyStore();
      when(() => mockSessionKeys.currentAccountKey).thenReturn(null);
      repository = MockChatRepository(
        crypto: FakeCryptographyService(),
        sessionKeys: mockSessionKeys,
      );
    });

    test(
      'sendQuery returns AnswerResult with mocked answer and conversationId',
      () async {
        final result = await repository.sendQuery(
          'What is the capital of France?',
        );

        expect(result, isA<AnswerResult>());
        expect(result.answer, contains('What is the capital of France?'));
        expect(result.conversationId, 'mock-conv-7');
        expect(result.citations.length, 1);
      },
    );

    test(
      'sendQuery with guestSessionId throws RateLimitException after limit',
      () async {
        final limit = AppStrings.guestQueryLimit;
        for (var i = 0; i < limit; i++) {
          final result = await repository.sendQuery(
            'Query $i',
            guestSessionId: 'guest123',
          );
          expect(result.answer, isNotEmpty);
        }

        expect(
          () async => await repository.sendQuery(
            'Rate Limit Query',
            guestSessionId: 'guest123',
          ),
          throwsException,
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
