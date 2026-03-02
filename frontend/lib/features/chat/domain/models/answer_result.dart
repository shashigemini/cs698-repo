import 'package:flutter/foundation.dart';
import 'citation.dart';

/// The result returned by the RAG system for a user query.
///
/// Contains the AI-generated [answer], any [citations] from
/// source documents, and the [conversationId] to continue the
/// conversation.
@immutable
class AnswerResult {
  /// The AI-generated answer text.
  final String answer;

  /// Source document citations supporting the answer.
  final List<Citation> citations;

  /// Identifier for continuing this conversation, or `null`
  /// for guest sessions.
  final String? conversationId;

  /// Optional metadata from the RAG pipeline (e.g. timings).
  final Map<String, dynamic>? metadata;

  /// Creates an [AnswerResult].
  const AnswerResult({
    required this.answer,
    this.citations = const [],
    this.conversationId,
    this.metadata,
  });
}
