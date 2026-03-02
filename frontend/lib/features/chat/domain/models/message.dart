import 'package:flutter/foundation.dart';
import 'citation.dart';

/// A single chat message in a conversation.
///
/// Messages are either from the user (`sender == 'user'`) or
/// from the AI assistant (`sender == 'assistant'`). Assistant
/// messages may include [citations] referencing source documents.
@immutable
class Message {
  /// Unique identifier for this message.
  final String id;

  /// Who sent the message: `'user'` or `'assistant'`.
  final String sender;

  /// The text content of the message.
  final String content;

  /// Source document citations (assistant messages only).
  final List<Citation> citations;

  /// When the message was created.
  final DateTime timestamp;

  /// Creates a [Message].
  const Message({
    required this.id,
    required this.sender,
    required this.content,
    this.citations = const [],
    required this.timestamp,
  });

  /// Creates a copy of this message with the given fields replaced.
  Message copyWith({
    String? id,
    String? sender,
    String? content,
    List<Citation>? citations,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Creates a [Message] from a JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      citations:
          (json['citations'] as List<dynamic>?)
              ?.map((e) => Citation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts this [Message] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'citations': citations.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
