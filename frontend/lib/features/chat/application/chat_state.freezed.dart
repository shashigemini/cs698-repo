// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatState {
  List<Message> get messages;
  bool get isLoading;
  String? get error;
  String? get conversationId;
  bool get rateLimitExceeded;
  int get guestQueriesRemaining;
  List<Conversation> get recentConversations;
  int get queryUsage;
  int get totalUsageLimit;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChatStateCopyWith<ChatState> get copyWith =>
      _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChatState &&
            const DeepCollectionEquality().equals(other.messages, messages) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.rateLimitExceeded, rateLimitExceeded) ||
                other.rateLimitExceeded == rateLimitExceeded) &&
            (identical(other.guestQueriesRemaining, guestQueriesRemaining) ||
                other.guestQueriesRemaining == guestQueriesRemaining) &&
            const DeepCollectionEquality()
                .equals(other.recentConversations, recentConversations) &&
            (identical(other.queryUsage, queryUsage) ||
                other.queryUsage == queryUsage) &&
            (identical(other.totalUsageLimit, totalUsageLimit) ||
                other.totalUsageLimit == totalUsageLimit));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(messages),
      isLoading,
      error,
      conversationId,
      rateLimitExceeded,
      guestQueriesRemaining,
      const DeepCollectionEquality().hash(recentConversations),
      queryUsage,
      totalUsageLimit);

  @override
  String toString() {
    return 'ChatState(messages: $messages, isLoading: $isLoading, error: $error, conversationId: $conversationId, rateLimitExceeded: $rateLimitExceeded, guestQueriesRemaining: $guestQueriesRemaining, recentConversations: $recentConversations, queryUsage: $queryUsage, totalUsageLimit: $totalUsageLimit)';
  }
}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) =
      _$ChatStateCopyWithImpl;
  @useResult
  $Res call(
      {List<Message> messages,
      bool isLoading,
      String? error,
      String? conversationId,
      bool rateLimitExceeded,
      int guestQueriesRemaining,
      List<Conversation> recentConversations,
      int queryUsage,
      int totalUsageLimit});
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res> implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? conversationId = freezed,
    Object? rateLimitExceeded = null,
    Object? guestQueriesRemaining = null,
    Object? recentConversations = null,
    Object? queryUsage = null,
    Object? totalUsageLimit = null,
  }) {
    return _then(_self.copyWith(
      messages: null == messages
          ? _self.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<Message>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      conversationId: freezed == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      rateLimitExceeded: null == rateLimitExceeded
          ? _self.rateLimitExceeded
          : rateLimitExceeded // ignore: cast_nullable_to_non_nullable
              as bool,
      guestQueriesRemaining: null == guestQueriesRemaining
          ? _self.guestQueriesRemaining
          : guestQueriesRemaining // ignore: cast_nullable_to_non_nullable
              as int,
      recentConversations: null == recentConversations
          ? _self.recentConversations
          : recentConversations // ignore: cast_nullable_to_non_nullable
              as List<Conversation>,
      queryUsage: null == queryUsage
          ? _self.queryUsage
          : queryUsage // ignore: cast_nullable_to_non_nullable
              as int,
      totalUsageLimit: null == totalUsageLimit
          ? _self.totalUsageLimit
          : totalUsageLimit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
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
    TResult Function(_ChatState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ChatState() when $default != null:
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
    TResult Function(_ChatState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChatState():
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
    TResult? Function(_ChatState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChatState() when $default != null:
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
    TResult Function(
            List<Message> messages,
            bool isLoading,
            String? error,
            String? conversationId,
            bool rateLimitExceeded,
            int guestQueriesRemaining,
            List<Conversation> recentConversations,
            int queryUsage,
            int totalUsageLimit)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ChatState() when $default != null:
        return $default(
            _that.messages,
            _that.isLoading,
            _that.error,
            _that.conversationId,
            _that.rateLimitExceeded,
            _that.guestQueriesRemaining,
            _that.recentConversations,
            _that.queryUsage,
            _that.totalUsageLimit);
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
    TResult Function(
            List<Message> messages,
            bool isLoading,
            String? error,
            String? conversationId,
            bool rateLimitExceeded,
            int guestQueriesRemaining,
            List<Conversation> recentConversations,
            int queryUsage,
            int totalUsageLimit)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChatState():
        return $default(
            _that.messages,
            _that.isLoading,
            _that.error,
            _that.conversationId,
            _that.rateLimitExceeded,
            _that.guestQueriesRemaining,
            _that.recentConversations,
            _that.queryUsage,
            _that.totalUsageLimit);
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
    TResult? Function(
            List<Message> messages,
            bool isLoading,
            String? error,
            String? conversationId,
            bool rateLimitExceeded,
            int guestQueriesRemaining,
            List<Conversation> recentConversations,
            int queryUsage,
            int totalUsageLimit)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChatState() when $default != null:
        return $default(
            _that.messages,
            _that.isLoading,
            _that.error,
            _that.conversationId,
            _that.rateLimitExceeded,
            _that.guestQueriesRemaining,
            _that.recentConversations,
            _that.queryUsage,
            _that.totalUsageLimit);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ChatState implements ChatState {
  const _ChatState(
      {final List<Message> messages = const [],
      this.isLoading = false,
      this.error,
      this.conversationId,
      this.rateLimitExceeded = false,
      this.guestQueriesRemaining = AppStrings.guestQueryLimit,
      final List<Conversation> recentConversations = const [],
      this.queryUsage = 0,
      this.totalUsageLimit = AppStrings.totalUsageLimit})
      : _messages = messages,
        _recentConversations = recentConversations;

  final List<Message> _messages;
  @override
  @JsonKey()
  List<Message> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;
  @override
  final String? conversationId;
  @override
  @JsonKey()
  final bool rateLimitExceeded;
  @override
  @JsonKey()
  final int guestQueriesRemaining;
  final List<Conversation> _recentConversations;
  @override
  @JsonKey()
  List<Conversation> get recentConversations {
    if (_recentConversations is EqualUnmodifiableListView)
      return _recentConversations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentConversations);
  }

  @override
  @JsonKey()
  final int queryUsage;
  @override
  @JsonKey()
  final int totalUsageLimit;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChatStateCopyWith<_ChatState> get copyWith =>
      __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChatState &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.rateLimitExceeded, rateLimitExceeded) ||
                other.rateLimitExceeded == rateLimitExceeded) &&
            (identical(other.guestQueriesRemaining, guestQueriesRemaining) ||
                other.guestQueriesRemaining == guestQueriesRemaining) &&
            const DeepCollectionEquality()
                .equals(other._recentConversations, _recentConversations) &&
            (identical(other.queryUsage, queryUsage) ||
                other.queryUsage == queryUsage) &&
            (identical(other.totalUsageLimit, totalUsageLimit) ||
                other.totalUsageLimit == totalUsageLimit));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_messages),
      isLoading,
      error,
      conversationId,
      rateLimitExceeded,
      guestQueriesRemaining,
      const DeepCollectionEquality().hash(_recentConversations),
      queryUsage,
      totalUsageLimit);

  @override
  String toString() {
    return 'ChatState(messages: $messages, isLoading: $isLoading, error: $error, conversationId: $conversationId, rateLimitExceeded: $rateLimitExceeded, guestQueriesRemaining: $guestQueriesRemaining, recentConversations: $recentConversations, queryUsage: $queryUsage, totalUsageLimit: $totalUsageLimit)';
  }
}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res>
    implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(
          _ChatState value, $Res Function(_ChatState) _then) =
      __$ChatStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<Message> messages,
      bool isLoading,
      String? error,
      String? conversationId,
      bool rateLimitExceeded,
      int guestQueriesRemaining,
      List<Conversation> recentConversations,
      int queryUsage,
      int totalUsageLimit});
}

/// @nodoc
class __$ChatStateCopyWithImpl<$Res> implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? messages = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? conversationId = freezed,
    Object? rateLimitExceeded = null,
    Object? guestQueriesRemaining = null,
    Object? recentConversations = null,
    Object? queryUsage = null,
    Object? totalUsageLimit = null,
  }) {
    return _then(_ChatState(
      messages: null == messages
          ? _self._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<Message>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      conversationId: freezed == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      rateLimitExceeded: null == rateLimitExceeded
          ? _self.rateLimitExceeded
          : rateLimitExceeded // ignore: cast_nullable_to_non_nullable
              as bool,
      guestQueriesRemaining: null == guestQueriesRemaining
          ? _self.guestQueriesRemaining
          : guestQueriesRemaining // ignore: cast_nullable_to_non_nullable
              as int,
      recentConversations: null == recentConversations
          ? _self._recentConversations
          : recentConversations // ignore: cast_nullable_to_non_nullable
              as List<Conversation>,
      queryUsage: null == queryUsage
          ? _self.queryUsage
          : queryUsage // ignore: cast_nullable_to_non_nullable
              as int,
      totalUsageLimit: null == totalUsageLimit
          ? _self.totalUsageLimit
          : totalUsageLimit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
