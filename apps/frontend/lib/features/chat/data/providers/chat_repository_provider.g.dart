// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active [ChatRepository] implementation.
///
/// Currently returns [MockChatRepository]; swap for a real
/// implementation when the backend is available.

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

/// Provides the active [ChatRepository] implementation.
///
/// Currently returns [MockChatRepository]; swap for a real
/// implementation when the backend is available.

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  /// Provides the active [ChatRepository] implementation.
  ///
  /// Currently returns [MockChatRepository]; swap for a real
  /// implementation when the backend is available.
  ChatRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'chatRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'c8fa8bde00c8be46211a71356368a7d80e28fc58';
