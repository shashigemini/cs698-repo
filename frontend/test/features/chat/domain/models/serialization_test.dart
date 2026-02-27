import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/domain/models/conversation.dart';
import 'package:frontend/features/chat/domain/models/citation.dart';
import 'package:frontend/features/chat/domain/models/message.dart';

void main() {
  group('Chat Model Serialization', () {
    test('Conversation serialization', () {
      final now = DateTime.now();
      final conversation = Conversation(id: '1', title: 'Test', createdAt: now);

      final json = conversation.toJson();
      expect(json['id'], '1');
      expect(json['title'], 'Test');
      expect(json['created_at'], now.toIso8601String());

      final fromJson = Conversation.fromJson(json);
      expect(fromJson.id, conversation.id);
      expect(fromJson.title, conversation.title);
      expect(fromJson.createdAt, conversation.createdAt);
    });

    test('Citation serialization', () {
      const citation = Citation(
        documentId: 'doc1',
        title: 'Source',
        page: 10,
        paragraphId: 'p1',
        relevanceScore: 0.95,
        passageText: 'Sample text',
      );

      final json = citation.toJson();
      expect(json['document_id'], 'doc1');
      expect(json['title'], 'Source');
      expect(json['page'], 10);
      expect(json['relevance_score'], 0.95);

      final fromJson = Citation.fromJson(json);
      expect(fromJson.documentId, citation.documentId);
      expect(fromJson.title, citation.title);
      expect(fromJson.page, citation.page);
      expect(fromJson.relevanceScore, citation.relevanceScore);
      expect(fromJson.passageText, citation.passageText);
    });

    test('Message serialization', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg1',
        sender: 'user',
        content: 'Hello',
        timestamp: now,
        citations: [
          const Citation(
            documentId: 'doc1',
            title: 'Ref',
            page: 1,
            paragraphId: 'p1',
          ),
        ],
      );

      final json = message.toJson();
      expect(json['id'], 'msg1');
      expect(json['sender'], 'user');
      expect(json['citations'], isA<List<dynamic>>());
      expect((json['citations'] as List).length, 1);

      final fromJson = Message.fromJson(json);
      expect(fromJson.id, message.id);
      expect(fromJson.sender, message.sender);
      expect(fromJson.citations.length, 1);
      expect(fromJson.citations.first.documentId, 'doc1');
      expect(fromJson.timestamp.toIso8601String(), now.toIso8601String());
    });
  });
}
