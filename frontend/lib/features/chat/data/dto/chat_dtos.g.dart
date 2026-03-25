// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueryRequestDto _$QueryRequestDtoFromJson(Map<String, dynamic> json) =>
    _QueryRequestDto(
      query: json['query'] as String,
      conversationId: json['conversation_id'] as String?,
    );

Map<String, dynamic> _$QueryRequestDtoToJson(_QueryRequestDto instance) =>
    <String, dynamic>{
      'query': instance.query,
      'conversation_id': instance.conversationId,
    };

_AnswerResponseDto _$AnswerResponseDtoFromJson(Map<String, dynamic> json) =>
    _AnswerResponseDto(
      answer: json['answer'] as String,
      conversationId: json['conversation_id'] as String?,
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => CitationDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AnswerResponseDtoToJson(_AnswerResponseDto instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'conversation_id': instance.conversationId,
      'citations': instance.citations,
      'suggestions': instance.suggestions,
    };

_CitationDto _$CitationDtoFromJson(Map<String, dynamic> json) => _CitationDto(
      documentId: json['document_id'] as String,
      title: json['title'] as String,
      page: (json['page'] as num).toInt(),
      paragraphId: json['paragraph_id'] as String,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble(),
      passageText: json['passage_text'] as String?,
    );

Map<String, dynamic> _$CitationDtoToJson(_CitationDto instance) =>
    <String, dynamic>{
      'document_id': instance.documentId,
      'title': instance.title,
      'page': instance.page,
      'paragraph_id': instance.paragraphId,
      'relevance_score': instance.relevanceScore,
      'passage_text': instance.passageText,
    };
