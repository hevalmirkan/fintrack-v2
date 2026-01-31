import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../features/insights/domain/services/financial_terms_database.dart';

/// Notification service for scheduling financial coaching notifications
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  factory NotificationService() => instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Reset singleton (for testing or after data clear)
  static void reset() {
    _instance?._initialized = false;
    _instance = null;
  }

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      // Android initialization
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
    } catch (e) {
      print('NotificationService initialization error: $e');
      _initialized = false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Show test notification immediately
  Future<void> showTestNotification() async {
    await initialize();

    if (!await requestPermissions()) {
      throw Exception('Notification permission denied');
    }

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Bildirimler Aktif! 🎉',
      'FinTrack bildirimleri başarıyla ayarlandı. Günlük finans ipuçları için hazır!',
      details,
      payload: 'test',
    );
  }

  /// Schedule daily financial term notification (09:00 AM)
  Future<void> scheduleDailyTerm(bool enable) async {
    await initialize();

    if (!enable) {
      await _notifications.cancel(1);
      return;
    }

    if (!await requestPermissions()) {
      return;
    }

    // Get random term from database
    final term = FinancialTermsDatabase.getRandomTerm();

    const androidDetails = AndroidNotificationDetails(
      'daily_term_channel',
      'Günlük Finans Terimi',
      channelDescription: 'Günlük finansal eğitim bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 09:00 AM daily
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 09:00 AM
      0,
    );

    // If 09:00 has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      1,
      'Günün Finans Terimi 💡',
      '${term.title}: ${_truncate(term.definition, 80)}',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'daily_term:${term.title}',
    );
  }

  /// Schedule weekly financial report (Sunday 21:00)
  Future<void> scheduleWeeklyReport(bool enable) async {
    await initialize();

    if (!enable) {
      await _notifications.cancel(2);
      return;
    }

    if (!await requestPermissions()) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'weekly_report_channel',
      'Haftalık Rapor',
      channelDescription: 'Haftalık finansal sağlık raporu',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for Sunday 21:00 (9 PM)
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = _nextSunday(now, 21, 0);

    // If it's already past Sunday 21:00, schedule for next Sunday
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _notifications.zonedSchedule(
      2,
      'Haftalık Finansal Rapor 📊',
      'Finansal sağlık skorunu kontrol etme zamanı! Yeni haftaya hazır mısın?',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_report',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  /// Helper: Get next Sunday at specified time
  tz.TZDateTime _nextSunday(tz.TZDateTime from, int hour, int minute) {
    var scheduledDate = tz.TZDateTime(
      tz.local,
      from.year,
      from.month,
      from.day,
      hour,
      minute,
    );

    // Add days until we reach Sunday (weekday 7)
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Helper: Truncate text
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
