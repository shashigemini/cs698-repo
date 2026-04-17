// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoginRequestDto {

 String get email; String get password;
/// Create a copy of LoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginRequestDtoCopyWith<LoginRequestDto> get copyWith => _$LoginRequestDtoCopyWithImpl<LoginRequestDto>(this as LoginRequestDto, _$identity);

  /// Serializes this LoginRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString() {
  return 'LoginRequestDto(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class $LoginRequestDtoCopyWith<$Res>  {
  factory $LoginRequestDtoCopyWith(LoginRequestDto value, $Res Function(LoginRequestDto) _then) = _$LoginRequestDtoCopyWithImpl;
@useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class _$LoginRequestDtoCopyWithImpl<$Res>
    implements $LoginRequestDtoCopyWith<$Res> {
  _$LoginRequestDtoCopyWithImpl(this._self, this._then);

  final LoginRequestDto _self;
  final $Res Function(LoginRequestDto) _then;

/// Create a copy of LoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? password = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginRequestDto].
extension LoginRequestDtoPatterns on LoginRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _LoginRequestDto():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _LoginRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginRequestDto() when $default != null:
return $default(_that.email,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String password)  $default,) {final _that = this;
switch (_that) {
case _LoginRequestDto():
return $default(_that.email,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String password)?  $default,) {final _that = this;
switch (_that) {
case _LoginRequestDto() when $default != null:
return $default(_that.email,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoginRequestDto implements LoginRequestDto {
  const _LoginRequestDto({required this.email, required this.password});
  factory _LoginRequestDto.fromJson(Map<String, dynamic> json) => _$LoginRequestDtoFromJson(json);

@override final  String email;
@override final  String password;

/// Create a copy of LoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginRequestDtoCopyWith<_LoginRequestDto> get copyWith => __$LoginRequestDtoCopyWithImpl<_LoginRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoginRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString() {
  return 'LoginRequestDto(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class _$LoginRequestDtoCopyWith<$Res> implements $LoginRequestDtoCopyWith<$Res> {
  factory _$LoginRequestDtoCopyWith(_LoginRequestDto value, $Res Function(_LoginRequestDto) _then) = __$LoginRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class __$LoginRequestDtoCopyWithImpl<$Res>
    implements _$LoginRequestDtoCopyWith<$Res> {
  __$LoginRequestDtoCopyWithImpl(this._self, this._then);

  final _LoginRequestDto _self;
  final $Res Function(_LoginRequestDto) _then;

/// Create a copy of LoginRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(_LoginRequestDto(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RegisterRequestDto {

 String get email; String get password; String? get fullName; String? get clientAuthToken; String? get salt; String? get wrappedAccountKey; String? get recoveryWrappedAk;
/// Create a copy of RegisterRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterRequestDtoCopyWith<RegisterRequestDto> get copyWith => _$RegisterRequestDtoCopyWithImpl<RegisterRequestDto>(this as RegisterRequestDto, _$identity);

  /// Serializes this RegisterRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.clientAuthToken, clientAuthToken) || other.clientAuthToken == clientAuthToken)&&(identical(other.salt, salt) || other.salt == salt)&&(identical(other.wrappedAccountKey, wrappedAccountKey) || other.wrappedAccountKey == wrappedAccountKey)&&(identical(other.recoveryWrappedAk, recoveryWrappedAk) || other.recoveryWrappedAk == recoveryWrappedAk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,fullName,clientAuthToken,salt,wrappedAccountKey,recoveryWrappedAk);

@override
String toString() {
  return 'RegisterRequestDto(email: $email, password: $password, fullName: $fullName, clientAuthToken: $clientAuthToken, salt: $salt, wrappedAccountKey: $wrappedAccountKey, recoveryWrappedAk: $recoveryWrappedAk)';
}


}

/// @nodoc
abstract mixin class $RegisterRequestDtoCopyWith<$Res>  {
  factory $RegisterRequestDtoCopyWith(RegisterRequestDto value, $Res Function(RegisterRequestDto) _then) = _$RegisterRequestDtoCopyWithImpl;
@useResult
$Res call({
 String email, String password, String? fullName, String? clientAuthToken, String? salt, String? wrappedAccountKey, String? recoveryWrappedAk
});




}
/// @nodoc
class _$RegisterRequestDtoCopyWithImpl<$Res>
    implements $RegisterRequestDtoCopyWith<$Res> {
  _$RegisterRequestDtoCopyWithImpl(this._self, this._then);

  final RegisterRequestDto _self;
  final $Res Function(RegisterRequestDto) _then;

/// Create a copy of RegisterRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? password = null,Object? fullName = freezed,Object? clientAuthToken = freezed,Object? salt = freezed,Object? wrappedAccountKey = freezed,Object? recoveryWrappedAk = freezed,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,clientAuthToken: freezed == clientAuthToken ? _self.clientAuthToken : clientAuthToken // ignore: cast_nullable_to_non_nullable
as String?,salt: freezed == salt ? _self.salt : salt // ignore: cast_nullable_to_non_nullable
as String?,wrappedAccountKey: freezed == wrappedAccountKey ? _self.wrappedAccountKey : wrappedAccountKey // ignore: cast_nullable_to_non_nullable
as String?,recoveryWrappedAk: freezed == recoveryWrappedAk ? _self.recoveryWrappedAk : recoveryWrappedAk // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterRequestDto].
extension RegisterRequestDtoPatterns on RegisterRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _RegisterRequestDto():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String password,  String? fullName,  String? clientAuthToken,  String? salt,  String? wrappedAccountKey,  String? recoveryWrappedAk)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterRequestDto() when $default != null:
return $default(_that.email,_that.password,_that.fullName,_that.clientAuthToken,_that.salt,_that.wrappedAccountKey,_that.recoveryWrappedAk);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String password,  String? fullName,  String? clientAuthToken,  String? salt,  String? wrappedAccountKey,  String? recoveryWrappedAk)  $default,) {final _that = this;
switch (_that) {
case _RegisterRequestDto():
return $default(_that.email,_that.password,_that.fullName,_that.clientAuthToken,_that.salt,_that.wrappedAccountKey,_that.recoveryWrappedAk);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String password,  String? fullName,  String? clientAuthToken,  String? salt,  String? wrappedAccountKey,  String? recoveryWrappedAk)?  $default,) {final _that = this;
switch (_that) {
case _RegisterRequestDto() when $default != null:
return $default(_that.email,_that.password,_that.fullName,_that.clientAuthToken,_that.salt,_that.wrappedAccountKey,_that.recoveryWrappedAk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegisterRequestDto implements RegisterRequestDto {
  const _RegisterRequestDto({required this.email, required this.password, this.fullName, this.clientAuthToken, this.salt, this.wrappedAccountKey, this.recoveryWrappedAk});
  factory _RegisterRequestDto.fromJson(Map<String, dynamic> json) => _$RegisterRequestDtoFromJson(json);

@override final  String email;
@override final  String password;
@override final  String? fullName;
@override final  String? clientAuthToken;
@override final  String? salt;
@override final  String? wrappedAccountKey;
@override final  String? recoveryWrappedAk;

/// Create a copy of RegisterRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterRequestDtoCopyWith<_RegisterRequestDto> get copyWith => __$RegisterRequestDtoCopyWithImpl<_RegisterRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegisterRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.clientAuthToken, clientAuthToken) || other.clientAuthToken == clientAuthToken)&&(identical(other.salt, salt) || other.salt == salt)&&(identical(other.wrappedAccountKey, wrappedAccountKey) || other.wrappedAccountKey == wrappedAccountKey)&&(identical(other.recoveryWrappedAk, recoveryWrappedAk) || other.recoveryWrappedAk == recoveryWrappedAk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,fullName,clientAuthToken,salt,wrappedAccountKey,recoveryWrappedAk);

@override
String toString() {
  return 'RegisterRequestDto(email: $email, password: $password, fullName: $fullName, clientAuthToken: $clientAuthToken, salt: $salt, wrappedAccountKey: $wrappedAccountKey, recoveryWrappedAk: $recoveryWrappedAk)';
}


}

/// @nodoc
abstract mixin class _$RegisterRequestDtoCopyWith<$Res> implements $RegisterRequestDtoCopyWith<$Res> {
  factory _$RegisterRequestDtoCopyWith(_RegisterRequestDto value, $Res Function(_RegisterRequestDto) _then) = __$RegisterRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String email, String password, String? fullName, String? clientAuthToken, String? salt, String? wrappedAccountKey, String? recoveryWrappedAk
});




}
/// @nodoc
class __$RegisterRequestDtoCopyWithImpl<$Res>
    implements _$RegisterRequestDtoCopyWith<$Res> {
  __$RegisterRequestDtoCopyWithImpl(this._self, this._then);

  final _RegisterRequestDto _self;
  final $Res Function(_RegisterRequestDto) _then;

/// Create a copy of RegisterRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,Object? fullName = freezed,Object? clientAuthToken = freezed,Object? salt = freezed,Object? wrappedAccountKey = freezed,Object? recoveryWrappedAk = freezed,}) {
  return _then(_RegisterRequestDto(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,clientAuthToken: freezed == clientAuthToken ? _self.clientAuthToken : clientAuthToken // ignore: cast_nullable_to_non_nullable
as String?,salt: freezed == salt ? _self.salt : salt // ignore: cast_nullable_to_non_nullable
as String?,wrappedAccountKey: freezed == wrappedAccountKey ? _self.wrappedAccountKey : wrappedAccountKey // ignore: cast_nullable_to_non_nullable
as String?,recoveryWrappedAk: freezed == recoveryWrappedAk ? _self.recoveryWrappedAk : recoveryWrappedAk // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TokenResponseDto {

 String get accessToken; String get refreshToken; String get accessExpiresAt;
/// Create a copy of TokenResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenResponseDtoCopyWith<TokenResponseDto> get copyWith => _$TokenResponseDtoCopyWithImpl<TokenResponseDto>(this as TokenResponseDto, _$identity);

  /// Serializes this TokenResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenResponseDto&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.accessExpiresAt, accessExpiresAt) || other.accessExpiresAt == accessExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,accessExpiresAt);

@override
String toString() {
  return 'TokenResponseDto(accessToken: $accessToken, refreshToken: $refreshToken, accessExpiresAt: $accessExpiresAt)';
}


}

/// @nodoc
abstract mixin class $TokenResponseDtoCopyWith<$Res>  {
  factory $TokenResponseDtoCopyWith(TokenResponseDto value, $Res Function(TokenResponseDto) _then) = _$TokenResponseDtoCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, String accessExpiresAt
});




}
/// @nodoc
class _$TokenResponseDtoCopyWithImpl<$Res>
    implements $TokenResponseDtoCopyWith<$Res> {
  _$TokenResponseDtoCopyWithImpl(this._self, this._then);

  final TokenResponseDto _self;
  final $Res Function(TokenResponseDto) _then;

/// Create a copy of TokenResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? accessExpiresAt = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,accessExpiresAt: null == accessExpiresAt ? _self.accessExpiresAt : accessExpiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenResponseDto].
extension TokenResponseDtoPatterns on TokenResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenResponseDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _TokenResponseDto():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _TokenResponseDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String accessExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenResponseDto() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.accessExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String accessExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _TokenResponseDto():
return $default(_that.accessToken,_that.refreshToken,_that.accessExpiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  String accessExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _TokenResponseDto() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.accessExpiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenResponseDto implements TokenResponseDto {
  const _TokenResponseDto({required this.accessToken, required this.refreshToken, required this.accessExpiresAt});
  factory _TokenResponseDto.fromJson(Map<String, dynamic> json) => _$TokenResponseDtoFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  String accessExpiresAt;

/// Create a copy of TokenResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenResponseDtoCopyWith<_TokenResponseDto> get copyWith => __$TokenResponseDtoCopyWithImpl<_TokenResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenResponseDto&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.accessExpiresAt, accessExpiresAt) || other.accessExpiresAt == accessExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,accessExpiresAt);

@override
String toString() {
  return 'TokenResponseDto(accessToken: $accessToken, refreshToken: $refreshToken, accessExpiresAt: $accessExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$TokenResponseDtoCopyWith<$Res> implements $TokenResponseDtoCopyWith<$Res> {
  factory _$TokenResponseDtoCopyWith(_TokenResponseDto value, $Res Function(_TokenResponseDto) _then) = __$TokenResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, String accessExpiresAt
});




}
/// @nodoc
class __$TokenResponseDtoCopyWithImpl<$Res>
    implements _$TokenResponseDtoCopyWith<$Res> {
  __$TokenResponseDtoCopyWithImpl(this._self, this._then);

  final _TokenResponseDto _self;
  final $Res Function(_TokenResponseDto) _then;

/// Create a copy of TokenResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? accessExpiresAt = null,}) {
  return _then(_TokenResponseDto(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,accessExpiresAt: null == accessExpiresAt ? _self.accessExpiresAt : accessExpiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChangePasswordRequestDto {

 String get newAuthToken; String get newWrappedAccountKey;
/// Create a copy of ChangePasswordRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangePasswordRequestDtoCopyWith<ChangePasswordRequestDto> get copyWith => _$ChangePasswordRequestDtoCopyWithImpl<ChangePasswordRequestDto>(this as ChangePasswordRequestDto, _$identity);

  /// Serializes this ChangePasswordRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordRequestDto&&(identical(other.newAuthToken, newAuthToken) || other.newAuthToken == newAuthToken)&&(identical(other.newWrappedAccountKey, newWrappedAccountKey) || other.newWrappedAccountKey == newWrappedAccountKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,newAuthToken,newWrappedAccountKey);

@override
String toString() {
  return 'ChangePasswordRequestDto(newAuthToken: $newAuthToken, newWrappedAccountKey: $newWrappedAccountKey)';
}


}

/// @nodoc
abstract mixin class $ChangePasswordRequestDtoCopyWith<$Res>  {
  factory $ChangePasswordRequestDtoCopyWith(ChangePasswordRequestDto value, $Res Function(ChangePasswordRequestDto) _then) = _$ChangePasswordRequestDtoCopyWithImpl;
@useResult
$Res call({
 String newAuthToken, String newWrappedAccountKey
});




}
/// @nodoc
class _$ChangePasswordRequestDtoCopyWithImpl<$Res>
    implements $ChangePasswordRequestDtoCopyWith<$Res> {
  _$ChangePasswordRequestDtoCopyWithImpl(this._self, this._then);

  final ChangePasswordRequestDto _self;
  final $Res Function(ChangePasswordRequestDto) _then;

/// Create a copy of ChangePasswordRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? newAuthToken = null,Object? newWrappedAccountKey = null,}) {
  return _then(_self.copyWith(
newAuthToken: null == newAuthToken ? _self.newAuthToken : newAuthToken // ignore: cast_nullable_to_non_nullable
as String,newWrappedAccountKey: null == newWrappedAccountKey ? _self.newWrappedAccountKey : newWrappedAccountKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangePasswordRequestDto].
extension ChangePasswordRequestDtoPatterns on ChangePasswordRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangePasswordRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangePasswordRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangePasswordRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _ChangePasswordRequestDto():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangePasswordRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChangePasswordRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String newAuthToken,  String newWrappedAccountKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangePasswordRequestDto() when $default != null:
return $default(_that.newAuthToken,_that.newWrappedAccountKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String newAuthToken,  String newWrappedAccountKey)  $default,) {final _that = this;
switch (_that) {
case _ChangePasswordRequestDto():
return $default(_that.newAuthToken,_that.newWrappedAccountKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String newAuthToken,  String newWrappedAccountKey)?  $default,) {final _that = this;
switch (_that) {
case _ChangePasswordRequestDto() when $default != null:
return $default(_that.newAuthToken,_that.newWrappedAccountKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangePasswordRequestDto implements ChangePasswordRequestDto {
  const _ChangePasswordRequestDto({required this.newAuthToken, required this.newWrappedAccountKey});
  factory _ChangePasswordRequestDto.fromJson(Map<String, dynamic> json) => _$ChangePasswordRequestDtoFromJson(json);

@override final  String newAuthToken;
@override final  String newWrappedAccountKey;

/// Create a copy of ChangePasswordRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangePasswordRequestDtoCopyWith<_ChangePasswordRequestDto> get copyWith => __$ChangePasswordRequestDtoCopyWithImpl<_ChangePasswordRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangePasswordRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangePasswordRequestDto&&(identical(other.newAuthToken, newAuthToken) || other.newAuthToken == newAuthToken)&&(identical(other.newWrappedAccountKey, newWrappedAccountKey) || other.newWrappedAccountKey == newWrappedAccountKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,newAuthToken,newWrappedAccountKey);

@override
String toString() {
  return 'ChangePasswordRequestDto(newAuthToken: $newAuthToken, newWrappedAccountKey: $newWrappedAccountKey)';
}


}

/// @nodoc
abstract mixin class _$ChangePasswordRequestDtoCopyWith<$Res> implements $ChangePasswordRequestDtoCopyWith<$Res> {
  factory _$ChangePasswordRequestDtoCopyWith(_ChangePasswordRequestDto value, $Res Function(_ChangePasswordRequestDto) _then) = __$ChangePasswordRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String newAuthToken, String newWrappedAccountKey
});




}
/// @nodoc
class __$ChangePasswordRequestDtoCopyWithImpl<$Res>
    implements _$ChangePasswordRequestDtoCopyWith<$Res> {
  __$ChangePasswordRequestDtoCopyWithImpl(this._self, this._then);

  final _ChangePasswordRequestDto _self;
  final $Res Function(_ChangePasswordRequestDto) _then;

/// Create a copy of ChangePasswordRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? newAuthToken = null,Object? newWrappedAccountKey = null,}) {
  return _then(_ChangePasswordRequestDto(
newAuthToken: null == newAuthToken ? _self.newAuthToken : newAuthToken // ignore: cast_nullable_to_non_nullable
as String,newWrappedAccountKey: null == newWrappedAccountKey ? _self.newWrappedAccountKey : newWrappedAccountKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RecoverAccountRequestDto {

 String get email; String get newAuthToken; String get newWrappedAccountKey;
/// Create a copy of RecoverAccountRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecoverAccountRequestDtoCopyWith<RecoverAccountRequestDto> get copyWith => _$RecoverAccountRequestDtoCopyWithImpl<RecoverAccountRequestDto>(this as RecoverAccountRequestDto, _$identity);

  /// Serializes this RecoverAccountRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecoverAccountRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.newAuthToken, newAuthToken) || other.newAuthToken == newAuthToken)&&(identical(other.newWrappedAccountKey, newWrappedAccountKey) || other.newWrappedAccountKey == newWrappedAccountKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,newAuthToken,newWrappedAccountKey);

@override
String toString() {
  return 'RecoverAccountRequestDto(email: $email, newAuthToken: $newAuthToken, newWrappedAccountKey: $newWrappedAccountKey)';
}


}

/// @nodoc
abstract mixin class $RecoverAccountRequestDtoCopyWith<$Res>  {
  factory $RecoverAccountRequestDtoCopyWith(RecoverAccountRequestDto value, $Res Function(RecoverAccountRequestDto) _then) = _$RecoverAccountRequestDtoCopyWithImpl;
@useResult
$Res call({
 String email, String newAuthToken, String newWrappedAccountKey
});




}
/// @nodoc
class _$RecoverAccountRequestDtoCopyWithImpl<$Res>
    implements $RecoverAccountRequestDtoCopyWith<$Res> {
  _$RecoverAccountRequestDtoCopyWithImpl(this._self, this._then);

  final RecoverAccountRequestDto _self;
  final $Res Function(RecoverAccountRequestDto) _then;

/// Create a copy of RecoverAccountRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? newAuthToken = null,Object? newWrappedAccountKey = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,newAuthToken: null == newAuthToken ? _self.newAuthToken : newAuthToken // ignore: cast_nullable_to_non_nullable
as String,newWrappedAccountKey: null == newWrappedAccountKey ? _self.newWrappedAccountKey : newWrappedAccountKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecoverAccountRequestDto].
extension RecoverAccountRequestDtoPatterns on RecoverAccountRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecoverAccountRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecoverAccountRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecoverAccountRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _RecoverAccountRequestDto():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecoverAccountRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _RecoverAccountRequestDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String newAuthToken,  String newWrappedAccountKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecoverAccountRequestDto() when $default != null:
return $default(_that.email,_that.newAuthToken,_that.newWrappedAccountKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String newAuthToken,  String newWrappedAccountKey)  $default,) {final _that = this;
switch (_that) {
case _RecoverAccountRequestDto():
return $default(_that.email,_that.newAuthToken,_that.newWrappedAccountKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String newAuthToken,  String newWrappedAccountKey)?  $default,) {final _that = this;
switch (_that) {
case _RecoverAccountRequestDto() when $default != null:
return $default(_that.email,_that.newAuthToken,_that.newWrappedAccountKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecoverAccountRequestDto implements RecoverAccountRequestDto {
  const _RecoverAccountRequestDto({required this.email, required this.newAuthToken, required this.newWrappedAccountKey});
  factory _RecoverAccountRequestDto.fromJson(Map<String, dynamic> json) => _$RecoverAccountRequestDtoFromJson(json);

@override final  String email;
@override final  String newAuthToken;
@override final  String newWrappedAccountKey;

/// Create a copy of RecoverAccountRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecoverAccountRequestDtoCopyWith<_RecoverAccountRequestDto> get copyWith => __$RecoverAccountRequestDtoCopyWithImpl<_RecoverAccountRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecoverAccountRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecoverAccountRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.newAuthToken, newAuthToken) || other.newAuthToken == newAuthToken)&&(identical(other.newWrappedAccountKey, newWrappedAccountKey) || other.newWrappedAccountKey == newWrappedAccountKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,newAuthToken,newWrappedAccountKey);

@override
String toString() {
  return 'RecoverAccountRequestDto(email: $email, newAuthToken: $newAuthToken, newWrappedAccountKey: $newWrappedAccountKey)';
}


}

/// @nodoc
abstract mixin class _$RecoverAccountRequestDtoCopyWith<$Res> implements $RecoverAccountRequestDtoCopyWith<$Res> {
  factory _$RecoverAccountRequestDtoCopyWith(_RecoverAccountRequestDto value, $Res Function(_RecoverAccountRequestDto) _then) = __$RecoverAccountRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String email, String newAuthToken, String newWrappedAccountKey
});




}
/// @nodoc
class __$RecoverAccountRequestDtoCopyWithImpl<$Res>
    implements _$RecoverAccountRequestDtoCopyWith<$Res> {
  __$RecoverAccountRequestDtoCopyWithImpl(this._self, this._then);

  final _RecoverAccountRequestDto _self;
  final $Res Function(_RecoverAccountRequestDto) _then;

/// Create a copy of RecoverAccountRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? newAuthToken = null,Object? newWrappedAccountKey = null,}) {
  return _then(_RecoverAccountRequestDto(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,newAuthToken: null == newAuthToken ? _self.newAuthToken : newAuthToken // ignore: cast_nullable_to_non_nullable
as String,newWrappedAccountKey: null == newWrappedAccountKey ? _self.newWrappedAccountKey : newWrappedAccountKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
