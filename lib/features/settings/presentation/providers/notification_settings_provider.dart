import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_service.dart';

part 'notification_settings_provider.g.dart';

/// Notification settings state
class NotificationSettingsState {
  final bool dailyNotificationsEnabled;
  final bool weeklyReportEnabled;
  final bool isLoading;

  const NotificationSettingsState({
    this.dailyNotificationsEnabled = false,
    this.weeklyReportEnabled = false,
    this.isLoading = false,
  });

  NotificationSettingsState copyWith({
    bool? dailyNotificationsEnabled,
    bool? weeklyReportEnabled,
    bool? isLoading,
  }) {
    return NotificationSettingsState(
      dailyNotificationsEnabled:
          dailyNotificationsEnabled ?? this.dailyNotificationsEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class NotificationSettings extends _$NotificationSettings {
  static const _keyDailyNotifications = 'daily_notifications_enabled';
  static const _keyWeeklyReport = 'weekly_report_enabled';

  SharedPreferences? _prefs;
  final _notificationService = NotificationService.instance;

  @override
  Future<NotificationSettingsState> build() async {
    // BUG FIX: Ensure proper initialization
    try {
      _prefs = await SharedPreferences.getInstance();
      await _notificationService.initialize();

      // Load saved settings
      final dailyEnabled = _prefs?.getBool(_keyDailyNotifications) ?? false;
      final weeklyEnabled = _prefs?.getBool(_keyWeeklyReport) ?? false;

      // BUG FIX: Apply saved settings to notification service AFTER loading
      if (dailyEnabled) {
        await _notificationService.scheduleDailyTerm(true);
      }
      if (weeklyEnabled) {
        await _notificationService.scheduleWeeklyReport(true);
      }

      return NotificationSettingsState(
        dailyNotificationsEnabled: dailyEnabled,
        weeklyReportEnabled: weeklyEnabled,
      );
    } catch (e) {
      print('Error initializing notification settings: $e');
      return const NotificationSettingsState();
    }
  }

  /// Toggle daily notifications
  Future<void> toggleDailyNotifications(bool enabled) async {
    try {
      // BUG FIX: Ensure prefs is initialized
      _prefs ??= await SharedPreferences.getInstance();

      // Save to SharedPreferences FIRST
      await _prefs!.setBool(_keyDailyNotifications, enabled);

      // Then schedule/cancel notification
      await _notificationService.scheduleDailyTerm(enabled);

      // Update state
      final current = state.when(
        data: (data) => data,
        loading: () => const NotificationSettingsState(),
        error: (_, __) => const NotificationSettingsState(),
      );
      state = AsyncData(current.copyWith(dailyNotificationsEnabled: enabled));
    } catch (e) {
      print('Error toggling daily notifications: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Toggle weekly report
  Future<void> toggleWeeklyReport(bool enabled) async {
    try {
      // BUG FIX: Ensure prefs is initialized
      _prefs ??= await SharedPreferences.getInstance();

      // Save to SharedPreferences FIRST
      await _prefs!.setBool(_keyWeeklyReport, enabled);

      // Then schedule/cancel notification
      await _notificationService.scheduleWeeklyReport(enabled);

      // Update state
      final current = state.when(
        data: (data) => data,
        loading: () => const NotificationSettingsState(),
        error: (_, __) => const NotificationSettingsState(),
      );
      state = AsyncData(current.copyWith(weeklyReportEnabled: enabled));
    } catch (e) {
      print('Error toggling weekly report: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Show test notification
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.showTestNotification();
    } catch (e) {
      print('Error sending test notification: $e');
      rethrow;
    }
  }

  /// Clear notification settings (BUG FIX: Safe clearing)
  Future<void> clearNotificationSettings() async {
    try {
      // Cancel notifications FIRST
      await _notificationService.cancelAllNotifications();

      // Then clear preferences
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(_keyDailyNotifications);
      await _prefs!.remove(_keyWeeklyReport);

      // Reset state
      state = const AsyncData(NotificationSettingsState());
    } catch (e) {
      print('Error clearing notification settings: $e');
    }
  }
}
