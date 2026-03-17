import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'cryptography_service.dart';

part 'cryptography_provider.g.dart';

/// Provider for [CryptographyService].
@riverpod
CryptographyService cryptographyService(Ref ref) {
  return CryptographyService();
}
