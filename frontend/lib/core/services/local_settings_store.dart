import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_settings_store.g.dart';

/// Provides the initialized [SharedPreferences] instance.
///
/// This provider must be overridden in the [ProviderScope] during app startup.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
}

/// Service for persisting non-sensitive application settings.
///
/// Uses [shared_preferences] for synchronous reads and efficient writes.
class LocalSettingsStore {
  final SharedPreferences _prefs;

  /// Creates a [LocalSettingsStore] with the given [SharedPreferences].
  LocalSettingsStore(this._prefs);

  static const _guestQueryCountKey = 'guestQueryCount';
  static const _lastQueryDateKey = 'lastQueryDate';

  /// Persists the guest query count.
  Future<void> saveGuestQueryCount(int count) async {
    await _prefs.setInt(_guestQueryCountKey, count);
  }

  /// Retrieves the guest query count. Returns 0 if not set.
  int getGuestQueryCount() {
    return _prefs.getInt(_guestQueryCountKey) ?? 0;
  }

  /// Persists the last query date.
  Future<void> saveLastQueryDate(DateTime date) async {
    await _prefs.setString(_lastQueryDateKey, date.toIso8601String());
  }

  /// Retrieves the last query date. Returns null if not set.
  DateTime? getLastQueryDate() {
    final dateStr = _prefs.getString(_lastQueryDateKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }
}

/// Provides the [LocalSettingsStore] instance.
@Riverpod(keepAlive: true)
LocalSettingsStore localSettingsStore(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalSettingsStore(prefs);
}
