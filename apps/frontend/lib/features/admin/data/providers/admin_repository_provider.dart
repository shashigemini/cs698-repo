import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/repositories/admin_repository.dart';
import '../repositories/api_admin_repository.dart';

part 'admin_repository_provider.g.dart';

/// Provides the [AdminRepository] instance.
@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ApiAdminRepository(dio: dio);
}
