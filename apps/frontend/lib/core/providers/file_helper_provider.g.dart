// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_helper_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileHelper)
final fileHelperProvider = FileHelperProvider._();

final class FileHelperProvider
    extends
        $FunctionalProvider<
          FileHelperInstance,
          FileHelperInstance,
          FileHelperInstance
        >
    with $Provider<FileHelperInstance> {
  FileHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileHelperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileHelperHash();

  @$internal
  @override
  $ProviderElement<FileHelperInstance> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FileHelperInstance create(Ref ref) {
    return fileHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileHelperInstance value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileHelperInstance>(value),
    );
  }
}

String _$fileHelperHash() => r'5b768218402f65b00d8c99f4c9333333fef8bab1';
