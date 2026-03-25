// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueryRequestDto {
  String get query;
  String? get conversationId;

  /// Create a copy of QueryRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QueryRequestDtoCopyWith<QueryRequestDto> get copyWith =>
      _$QueryRequestDtoCopyWithImpl<QueryRequestDto>(
          this as QueryRequestDto, _$identity);

  /// Serializes this QueryRequestDto to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QueryRequestDto &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, query, conversationId);

  @override
  String toString() {
    return 'QueryRequestDto(query: $query, conversationId: $conversationId)';
  }
}

/// @nodoc
abstract mixin class $QueryRequestDtoCopyWith<$Res> {
  factory $QueryRequestDtoCopyWith(
          QueryRequestDto value, $Res Function(QueryRequestDto) _then) =
      _$QueryRequestDtoCopyWithImpl;
  @useResult
  $Res call({String query, String? conversationId});
}

/// @nodoc
class _$QueryRequestDtoCopyWithImpl<$Res>
    implements $QueryRequestDtoCopyWith<$Res> {
  _$QueryRequestDtoCopyWithImpl(this._self, this._then);

  final QueryRequestDto _self;
  final $Res Function(QueryRequestDto) _then;

  /// Create a copy of QueryRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? conversationId = freezed,
  }) {
    return _then(_self.copyWith(
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: freezed == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [QueryRequestDto].
extension QueryRequestDtoPatterns on QueryRequestDto {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_QueryRequestDto value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QueryRequestDto() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_QueryRequestDto value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueryRequestDto():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_QueryRequestDto value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueryRequestDto() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String query, String? conversationId)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QueryRequestDto() when $default != null:
        return $default(_that.query, _that.conversationId);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String query, String? conversationId) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueryRequestDto():
        return $default(_that.query, _that.conversationId);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String query, String? conversationId)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueryRequestDto() when $default != null:
        return $default(_that.query, _that.conversationId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _QueryRequestDto implements QueryRequestDto {
  const _QueryRequestDto({required this.query, this.conversationId});
  factory _QueryRequestDto.fromJson(Map<String, dynamic> json) =>
      _$QueryRequestDtoFromJson(json);

  @override
  final String query;
  @override
  final String? conversationId;

  /// Create a copy of QueryRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QueryRequestDtoCopyWith<_QueryRequestDto> get copyWith =>
      __$QueryRequestDtoCopyWithImpl<_QueryRequestDto>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$QueryRequestDtoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QueryRequestDto &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, query, conversationId);

  @override
  String toString() {
    return 'QueryRequestDto(query: $query, conversationId: $conversationId)';
  }
}

/// @nodoc
abstract mixin class _$QueryRequestDtoCopyWith<$Res>
    implements $QueryRequestDtoCopyWith<$Res> {
  factory _$QueryRequestDtoCopyWith(
          _QueryRequestDto value, $Res Function(_QueryRequestDto) _then) =
      __$QueryRequestDtoCopyWithImpl;
  @override
  @useResult
  $Res call({String query, String? conversationId});
}

/// @nodoc
class __$QueryRequestDtoCopyWithImpl<$Res>
    implements _$QueryRequestDtoCopyWith<$Res> {
  __$QueryRequestDtoCopyWithImpl(this._self, this._then);

  final _QueryRequestDto _self;
  final $Res Function(_QueryRequestDto) _then;

  /// Create a copy of QueryRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? query = null,
    Object? conversationId = freezed,
  }) {
    return _then(_QueryRequestDto(
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: freezed == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$AnswerResponseDto {
  String get answer;
  String? get conversationId;
  List<CitationDto> get citations;
  List<String> get suggestions;

  /// Create a copy of AnswerResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AnswerResponseDtoCopyWith<AnswerResponseDto> get copyWith =>
      _$AnswerResponseDtoCopyWithImpl<AnswerResponseDto>(
          this as AnswerResponseDto, _$identity);

  /// Serializes this AnswerResponseDto to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AnswerResponseDto &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            const DeepCollectionEquality().equals(other.citations, citations) &&
            const DeepCollectionEquality()
                .equals(other.suggestions, suggestions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      answer,
      conversationId,
      const DeepCollectionEquality().hash(citations),
      const DeepCollectionEquality().hash(suggestions));

  @override
  String toString() {
    return 'AnswerResponseDto(answer: $answer, conversationId: $conversationId, citations: $citations, suggestions: $suggestions)';
  }
}

/// @nodoc
abstract mixin class $AnswerResponseDtoCopyWith<$Res> {
  factory $AnswerResponseDtoCopyWith(
          AnswerResponseDto value, $Res Function(AnswerResponseDto) _then) =
      _$AnswerResponseDtoCopyWithImpl;
  @useResult
  $Res call(
      {String answer,
      String? conversationId,
      List<CitationDto> citations,
      List<String> suggestions});
}

/// @nodoc
class _$AnswerResponseDtoCopyWithImpl<$Res>
    implements $AnswerResponseDtoCopyWith<$Res> {
  _$AnswerResponseDtoCopyWithImpl(this._self, this._then);

  final AnswerResponseDto _self;
  final $Res Function(AnswerResponseDto) _then;

  /// Create a copy of AnswerResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? answer = null,
    Object? conversationId = freezed,
    Object? citations = null,
    Object? suggestions = null,
  }) {
    return _then(_self.copyWith(
      answer: null == answer
          ? _self.answer
          : answer // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: freezed == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      citations: null == citations
          ? _self.citations
          : citations // ignore: cast_nullable_to_non_nullable
              as List<CitationDto>,
      suggestions: null == suggestions
          ? _self.suggestions
          : suggestions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [AnswerResponseDto].
extension AnswerResponseDtoPatterns on AnswerResponseDto {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AnswerResponseDto value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AnswerResponseDto() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AnswerResponseDto value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnswerResponseDto():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AnswerResponseDto value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnswerResponseDto() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String answer, String? conversationId,
            List<CitationDto> citations, List<String> suggestions)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AnswerResponseDto() when $default != null:
        return $default(_that.answer, _that.conversationId, _that.citations,
            _that.suggestions);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String answer, String? conversationId,
            List<CitationDto> citations, List<String> suggestions)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnswerResponseDto():
        return $default(_that.answer, _that.conversationId, _that.citations,
            _that.suggestions);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String answer, String? conversationId,
            List<CitationDto> citations, List<String> suggestions)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnswerResponseDto() when $default != null:
        return $default(_that.answer, _that.conversationId, _that.citations,
            _that.suggestions);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AnswerResponseDto implements AnswerResponseDto {
  const _AnswerResponseDto(
      {required this.answer,
      this.conversationId,
      final List<CitationDto> citations = const [],
      final List<String> suggestions = const []})
      : _citations = citations,
        _suggestions = suggestions;
  factory _AnswerResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AnswerResponseDtoFromJson(json);

  @override
  final String answer;
  @override
  final String? conversationId;
  final List<CitationDto> _citations;
  @override
  @JsonKey()
  List<CitationDto> get citations {
    if (_citations is EqualUnmodifiableListView) return _citations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_citations);
  }

  final List<String> _suggestions;
  @override
  @JsonKey()
  List<String> get suggestions {
    if (_suggestions is EqualUnmodifiableListView) return _suggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestions);
  }

  /// Create a copy of AnswerResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AnswerResponseDtoCopyWith<_AnswerResponseDto> get copyWith =>
      __$AnswerResponseDtoCopyWithImpl<_AnswerResponseDto>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AnswerResponseDtoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AnswerResponseDto &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            const DeepCollectionEquality()
                .equals(other._citations, _citations) &&
            const DeepCollectionEquality()
                .equals(other._suggestions, _suggestions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      answer,
      conversationId,
      const DeepCollectionEquality().hash(_citations),
      const DeepCollectionEquality().hash(_suggestions));

  @override
  String toString() {
    return 'AnswerResponseDto(answer: $answer, conversationId: $conversationId, citations: $citations, suggestions: $suggestions)';
  }
}

/// @nodoc
abstract mixin class _$AnswerResponseDtoCopyWith<$Res>
    implements $AnswerResponseDtoCopyWith<$Res> {
  factory _$AnswerResponseDtoCopyWith(
          _AnswerResponseDto value, $Res Function(_AnswerResponseDto) _then) =
      __$AnswerResponseDtoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String answer,
      String? conversationId,
      List<CitationDto> citations,
      List<String> suggestions});
}

/// @nodoc
class __$AnswerResponseDtoCopyWithImpl<$Res>
    implements _$AnswerResponseDtoCopyWith<$Res> {
  __$AnswerResponseDtoCopyWithImpl(this._self, this._then);

  final _AnswerResponseDto _self;
  final $Res Function(_AnswerResponseDto) _then;

  /// Create a copy of AnswerResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? answer = null,
    Object? conversationId = freezed,
    Object? citations = null,
    Object? suggestions = null,
  }) {
    return _then(_AnswerResponseDto(
      answer: null == answer
          ? _self.answer
          : answer // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: freezed == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      citations: null == citations
          ? _self._citations
          : citations // ignore: cast_nullable_to_non_nullable
              as List<CitationDto>,
      suggestions: null == suggestions
          ? _self._suggestions
          : suggestions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
mixin _$CitationDto {
  String get documentId;
  String get title;
  int get page;
  String get paragraphId;
  double? get relevanceScore;
  String? get passageText;

  /// Create a copy of CitationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CitationDtoCopyWith<CitationDto> get copyWith =>
      _$CitationDtoCopyWithImpl<CitationDto>(this as CitationDto, _$identity);

  /// Serializes this CitationDto to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CitationDto &&
            (identical(other.documentId, documentId) ||
                other.documentId == documentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.paragraphId, paragraphId) ||
                other.paragraphId == paragraphId) &&
            (identical(other.relevanceScore, relevanceScore) ||
                other.relevanceScore == relevanceScore) &&
            (identical(other.passageText, passageText) ||
                other.passageText == passageText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, documentId, title, page,
      paragraphId, relevanceScore, passageText);

  @override
  String toString() {
    return 'CitationDto(documentId: $documentId, title: $title, page: $page, paragraphId: $paragraphId, relevanceScore: $relevanceScore, passageText: $passageText)';
  }
}

/// @nodoc
abstract mixin class $CitationDtoCopyWith<$Res> {
  factory $CitationDtoCopyWith(
          CitationDto value, $Res Function(CitationDto) _then) =
      _$CitationDtoCopyWithImpl;
  @useResult
  $Res call(
      {String documentId,
      String title,
      int page,
      String paragraphId,
      double? relevanceScore,
      String? passageText});
}

/// @nodoc
class _$CitationDtoCopyWithImpl<$Res> implements $CitationDtoCopyWith<$Res> {
  _$CitationDtoCopyWithImpl(this._self, this._then);

  final CitationDto _self;
  final $Res Function(CitationDto) _then;

  /// Create a copy of CitationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? documentId = null,
    Object? title = null,
    Object? page = null,
    Object? paragraphId = null,
    Object? relevanceScore = freezed,
    Object? passageText = freezed,
  }) {
    return _then(_self.copyWith(
      documentId: null == documentId
          ? _self.documentId
          : documentId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      paragraphId: null == paragraphId
          ? _self.paragraphId
          : paragraphId // ignore: cast_nullable_to_non_nullable
              as String,
      relevanceScore: freezed == relevanceScore
          ? _self.relevanceScore
          : relevanceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      passageText: freezed == passageText
          ? _self.passageText
          : passageText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [CitationDto].
extension CitationDtoPatterns on CitationDto {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CitationDto value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CitationDto() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_CitationDto value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CitationDto():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_CitationDto value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CitationDto() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String documentId, String title, int page,
            String paragraphId, double? relevanceScore, String? passageText)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CitationDto() when $default != null:
        return $default(_that.documentId, _that.title, _that.page,
            _that.paragraphId, _that.relevanceScore, _that.passageText);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String documentId, String title, int page,
            String paragraphId, double? relevanceScore, String? passageText)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CitationDto():
        return $default(_that.documentId, _that.title, _that.page,
            _that.paragraphId, _that.relevanceScore, _that.passageText);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String documentId, String title, int page,
            String paragraphId, double? relevanceScore, String? passageText)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CitationDto() when $default != null:
        return $default(_that.documentId, _that.title, _that.page,
            _that.paragraphId, _that.relevanceScore, _that.passageText);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CitationDto implements CitationDto {
  const _CitationDto(
      {required this.documentId,
      required this.title,
      required this.page,
      required this.paragraphId,
      this.relevanceScore,
      this.passageText});
  factory _CitationDto.fromJson(Map<String, dynamic> json) =>
      _$CitationDtoFromJson(json);

  @override
  final String documentId;
  @override
  final String title;
  @override
  final int page;
  @override
  final String paragraphId;
  @override
  final double? relevanceScore;
  @override
  final String? passageText;

  /// Create a copy of CitationDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CitationDtoCopyWith<_CitationDto> get copyWith =>
      __$CitationDtoCopyWithImpl<_CitationDto>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CitationDtoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CitationDto &&
            (identical(other.documentId, documentId) ||
                other.documentId == documentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.paragraphId, paragraphId) ||
                other.paragraphId == paragraphId) &&
            (identical(other.relevanceScore, relevanceScore) ||
                other.relevanceScore == relevanceScore) &&
            (identical(other.passageText, passageText) ||
                other.passageText == passageText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, documentId, title, page,
      paragraphId, relevanceScore, passageText);

  @override
  String toString() {
    return 'CitationDto(documentId: $documentId, title: $title, page: $page, paragraphId: $paragraphId, relevanceScore: $relevanceScore, passageText: $passageText)';
  }
}

/// @nodoc
abstract mixin class _$CitationDtoCopyWith<$Res>
    implements $CitationDtoCopyWith<$Res> {
  factory _$CitationDtoCopyWith(
          _CitationDto value, $Res Function(_CitationDto) _then) =
      __$CitationDtoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String documentId,
      String title,
      int page,
      String paragraphId,
      double? relevanceScore,
      String? passageText});
}

/// @nodoc
class __$CitationDtoCopyWithImpl<$Res> implements _$CitationDtoCopyWith<$Res> {
  __$CitationDtoCopyWithImpl(this._self, this._then);

  final _CitationDto _self;
  final $Res Function(_CitationDto) _then;

  /// Create a copy of CitationDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? documentId = null,
    Object? title = null,
    Object? page = null,
    Object? paragraphId = null,
    Object? relevanceScore = freezed,
    Object? passageText = freezed,
  }) {
    return _then(_CitationDto(
      documentId: null == documentId
          ? _self.documentId
          : documentId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      paragraphId: null == paragraphId
          ? _self.paragraphId
          : paragraphId // ignore: cast_nullable_to_non_nullable
              as String,
      relevanceScore: freezed == relevanceScore
          ? _self.relevanceScore
          : relevanceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      passageText: freezed == passageText
          ? _self.passageText
          : passageText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
