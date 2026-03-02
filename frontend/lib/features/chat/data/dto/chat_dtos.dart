import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_dtos.freezed.dart';
part 'chat_dtos.g.dart';

@freezed
abstract class QueryRequestDto with _$QueryRequestDto {
  const factory QueryRequestDto({
    required String query,
    String? conversationId,
  }) = _QueryRequestDto;

  factory QueryRequestDto.fromJson(Map<String, dynamic> json) =>
      _$QueryRequestDtoFromJson(json);
}

@freezed
abstract class AnswerResponseDto with _$AnswerResponseDto {
  const factory AnswerResponseDto({
    required String answer,
    required String conversationId,
    required List<CitationDto> citations,
    required List<String> suggestions,
  }) = _AnswerResponseDto;

  factory AnswerResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AnswerResponseDtoFromJson(json);
}

@freezed
abstract class CitationDto with _$CitationDto {
  const factory CitationDto({
    required String sourceTitle,
    required String sourceUrl,
    required String snippet,
  }) = _CitationDto;

  factory CitationDto.fromJson(Map<String, dynamic> json) =>
      _$CitationDtoFromJson(json);
}
