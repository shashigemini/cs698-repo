import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_mode_provider.g.dart';

@riverpod
bool isDemoMode(Ref ref) {
  return false;
}
