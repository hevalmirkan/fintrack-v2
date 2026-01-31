import '../entities/user_settings.dart';

abstract class ISettingsRepository {
  /// Returns the user settings.
  /// Should return cached settings immediately if available,
  /// then fetch from remote if needed (implementation detail).
  Future<UserSettings> getSettings();

  /// Updates the user settings.
  Future<void> updateSettings(UserSettings settings);

  /// Updates only the base currency.
  Future<void> updateBaseCurrency(String currencyCode);
}
