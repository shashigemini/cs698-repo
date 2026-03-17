import 'package:flutter/foundation.dart';

/// A reference to a specific passage in a source document.
///
/// Citations are returned by the RAG system alongside answers
/// to indicate which parts of the proprietary texts informed
/// the response.
@immutable
class Citation {
  /// Unique identifier of the source document.
  final String documentId;

  /// Human-readable title of the source document.
  final String title;

  /// Page number within the document where the passage appears.
  final int page;

  /// Identifier of the paragraph within the page.
  final String paragraphId;

  /// Cosine-similarity score indicating how relevant the
  /// passage is to the original query (0.0–1.0).
  final double? relevanceScore;

  /// The actual scripture snippet for this citation.
  final String? passageText;

  /// Creates a [Citation].
  const Citation({
    required this.documentId,
    required this.title,
    required this.page,
    required this.paragraphId,
    this.relevanceScore,
    this.passageText,
  });

  /// Creates a [Citation] from a JSON map.
  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      documentId: json['document_id'] as String,
      title: json['title'] as String,
      page: json['page'] as int,
      paragraphId: json['paragraph_id'] as String,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble(),
      passageText: json['passage_text'] as String?,
    );
  }

  /// Converts this [Citation] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'title': title,
      'page': page,
      'paragraph_id': paragraphId,
      'relevance_score': relevanceScore,
      'passage_text': passageText,
    };
  }

  @override
  String toString() => '$title (p. $page)';
}
