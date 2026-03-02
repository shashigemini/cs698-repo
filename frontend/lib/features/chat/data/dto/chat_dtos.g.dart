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
      conversationId: json['conversation_id'] as String,
      citations: (json['citations'] as List<dynamic>)
          .map((e) => CitationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AnswerResponseDtoToJson(_AnswerResponseDto instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'conversation_id': instance.conversationId,
      'citations': instance.citations,
      'suggestions': instance.suggestions,
    };

_CitationDto _$CitationDtoFromJson(Map<String, dynamic> json) => _CitationDto(
  sourceTitle: json['source_title'] as String,
  sourceUrl: json['source_url'] as String,
  snippet: json['snippet'] as String,
);

Map<String, dynamic> _$CitationDtoToJson(_CitationDto instance) =>
    <String, dynamic>{
      'source_title': instance.sourceTitle,
      'source_url': instance.sourceUrl,
      'snippet': instance.snippet,
    };
