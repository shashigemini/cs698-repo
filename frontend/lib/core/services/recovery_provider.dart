import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'recovery_service.dart';

part 'recovery_provider.g.dart';

@Riverpod(keepAlive: true)
RecoveryService recoveryService(Ref ref) {
  return RecoveryService();
}
