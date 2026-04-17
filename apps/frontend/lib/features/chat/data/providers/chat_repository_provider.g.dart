// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active [ChatRepository] implementation.
///
/// Currently returns the live [ApiChatRepository] via delegation.

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

/// Provides the active [ChatRepository] implementation.
///
/// Currently returns the live [ApiChatRepository] via delegation.

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  /// Provides the active [ChatRepository] implementation.
  ///
  /// Currently returns the live [ApiChatRepository] via delegation.
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

String _$chatRepositoryHash() => r'696a8f0a06c20118a78ae75351f331e68929cf87';
