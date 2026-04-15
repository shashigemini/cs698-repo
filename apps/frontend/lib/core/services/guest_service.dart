import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_strings.dart';
import 'local_settings_store.dart';

part 'guest_service.g.dart';

/// Service responsible for managing guest user query limits and daily resets.
class GuestService {
  final LocalSettingsStore _store;

  /// Creates a [GuestService] with the given [LocalSettingsStore].
  GuestService(this._store);

  /// Returns the number of queries the guest has remaining for today.
  int getQueriesRemaining() {
    _checkDailyReset();
    final count = _store.getGuestQueryCount();
    return (AppStrings.guestQueryLimit - count).clamp(
      0,
      AppStrings.guestQueryLimit,
    );
  }

  /// Increments the guest's query usage.
  Future<void> incrementUsage() async {
    _checkDailyReset();
    final current = _store.getGuestQueryCount();
    await _store.saveGuestQueryCount(current + 1);
    await _store.saveLastQueryDate(DateTime.now().toUtc());
  }

  /// Resets the guest's usage if the current day is different from the last recorded query date.
  void _checkDailyReset() {
    final lastResetDate = _store.getLastQueryDate();
    final now = DateTime.now().toUtc();

    if (lastResetDate == null) {
      _store.saveLastQueryDate(now);
      return;
    }

    final isNewDay =
        now.year != lastResetDate.year ||
        now.month != lastResetDate.month ||
        now.day != lastResetDate.day;

    if (isNewDay) {
      _store.saveGuestQueryCount(0);
      _store.saveLastQueryDate(now);
    }
  }
}

/// Provides the [GuestService] instance.
@Riverpod(keepAlive: true)
GuestService guestService(Ref ref) {
  final store = ref.watch(localSettingsStoreProvider);
  return GuestService(store);
}
