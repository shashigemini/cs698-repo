// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    _LoginRequestDto(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(_LoginRequestDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

_RegisterRequestDto _$RegisterRequestDtoFromJson(Map<String, dynamic> json) =>
    _RegisterRequestDto(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['full_name'] as String?,
      clientAuthToken: json['client_auth_token'] as String?,
      salt: json['salt'] as String?,
      wrappedAccountKey: json['wrapped_account_key'] as String?,
      recoveryWrappedAk: json['recovery_wrapped_ak'] as String?,
    );

Map<String, dynamic> _$RegisterRequestDtoToJson(_RegisterRequestDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'full_name': instance.fullName,
      'client_auth_token': instance.clientAuthToken,
      'salt': instance.salt,
      'wrapped_account_key': instance.wrappedAccountKey,
      'recovery_wrapped_ak': instance.recoveryWrappedAk,
    };

_TokenResponseDto _$TokenResponseDtoFromJson(Map<String, dynamic> json) =>
    _TokenResponseDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresAt: json['access_expires_at'] as String,
    );

Map<String, dynamic> _$TokenResponseDtoToJson(_TokenResponseDto instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'access_expires_at': instance.accessExpiresAt,
    };

_ChangePasswordRequestDto _$ChangePasswordRequestDtoFromJson(
        Map<String, dynamic> json) =>
    _ChangePasswordRequestDto(
      newAuthToken: json['new_auth_token'] as String,
      newWrappedAccountKey: json['new_wrapped_account_key'] as String,
    );

Map<String, dynamic> _$ChangePasswordRequestDtoToJson(
        _ChangePasswordRequestDto instance) =>
    <String, dynamic>{
      'new_auth_token': instance.newAuthToken,
      'new_wrapped_account_key': instance.newWrappedAccountKey,
    };

_RecoverAccountRequestDto _$RecoverAccountRequestDtoFromJson(
        Map<String, dynamic> json) =>
    _RecoverAccountRequestDto(
      email: json['email'] as String,
      newAuthToken: json['new_auth_token'] as String,
      newWrappedAccountKey: json['new_wrapped_account_key'] as String,
    );

Map<String, dynamic> _$RecoverAccountRequestDtoToJson(
        _RecoverAccountRequestDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'new_auth_token': instance.newAuthToken,
      'new_wrapped_account_key': instance.newWrappedAccountKey,
    };
