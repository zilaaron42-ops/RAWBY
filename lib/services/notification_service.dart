// ============================================================
// RAWBY — Notification Service
// Handles Firebase Cloud Messaging (FCM) and local notifications
// ============================================================
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(apiServiceProvider), ref);
});

class NotificationService {
  final ApiService _api;
  final Ref _ref;
  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _firebaseReady = false;

  NotificationService(this._api, this._ref) {
    _initializeNotifications();
  }

  bool get _hasFirebase {
    if (_firebaseReady) return true;
    try {
      Firebase.app();
      _fcm ??= FirebaseMessaging.instance;
      _firebaseReady = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get _isMobilePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _initializeNotifications() async {
    if (!_isMobilePlatform) return;
    if (!_hasFirebase) return;
    try {
      await _fcm!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (_) {
      return;
    }

    // Local notifications setup
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Get and register FCM token
    _getAndRegisterToken();
  }

  Future<void> _getAndRegisterToken() async {
    if (!_isMobilePlatform) return;
    if (!_hasFirebase) return;
    if (!_ref.read(apiServiceProvider).hasAuthToken) return;
    try {
      String? token = await _fcm!.getToken();
      if (token != null) {
        await _api.registerFcmToken(token);
        _fcm!.onTokenRefresh.listen((newToken) {
          _api.registerFcmToken(newToken);
        });
      }
    } catch (_) {
      // Firebase unavailable on this platform (e.g., web without config)
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rawby_channel',
            'Rawby Notifications',
            channelDescription: 'Notifications for Rawby app',
            icon: android.smallIcon,
          ),
        ),
        payload: message.data['route'] as String?,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      // Navigate when notification is tapped
      // The router is accessed via the provider when needed by the UI layer
      debugPrint('Notification opened with route: $route');
    }
  }

  // ── Local Notifications ──────────────────────────────────────

  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String id,
  }) async {
    if (kIsWeb) return;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'rawby_channel_scheduled',
      'Rawby Scheduled Notifications',
      channelDescription: 'Daily scheduled notifications for Rawby app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id.hashCode,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Plugin unsupported on this platform
    }
  }

  Future<void> cancelNotification(String id) async {
    if (kIsWeb) return;
    try {
      await _flutterLocalNotificationsPlugin.cancel(id.hashCode);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (_) {}
  }

  // ── Specific Scheduled Notifications ─────────────────────────

  Future<void> scheduleDeadlineWarning(tz.TZDateTime deadline) async {
    final warningTime = deadline.subtract(const Duration(hours: 24));
    if (warningTime.isAfter(tz.TZDateTime.now(deadline.location))) {
      await scheduleDailyNotification(
        id: 'deadline_24h_warning',
        title: 'Project Due Soon!',
        body: 'Your weekly filmmaking project is due in 24 hours. Don\'t miss the deadline!',
        hour: warningTime.hour,
        minute: warningTime.minute,
      );
    }
  }

  Future<void> scheduleStatsReadyNotification(tz.TZDateTime statsUnlockDate) async {
    if (statsUnlockDate.isAfter(tz.TZDateTime.now(statsUnlockDate.location))) {
      await scheduleDailyNotification(
        id: 'stats_ready',
        title: 'Stats Ready!',
        body: 'Your project stats are ready to be recorded. Check it out!',
        hour: statsUnlockDate.hour,
        minute: statsUnlockDate.minute,
      );
    }
  }

  Future<void> scheduleWorkflowReminder(String taskId, String taskLabel, String day) async {
    // This would be more complex, matching day to next occurrence
    // For now, a simplified approach:
    final now = tz.TZDateTime.now(tz.local);
    int targetWeekday = _parseWeekday(day); // Map 'Friday' to 5, etc.

    if (targetWeekday == -1) return; // Invalid day

    int daysUntilTarget = (targetWeekday - now.weekday + 7) % 7;
    if (daysUntilTarget == 0) daysUntilTarget = 7; // Schedule for next week if today

    await scheduleDailyNotification(
      id: 'workflow_reminder_$taskId',
      title: 'Planned for today: $taskLabel',
      body: 'Time to work on your \'$taskLabel\' task!',
      hour: 9, // Example: 9 AM
      minute: 0,
    );
  }

  int _parseWeekday(String day) {
    switch (day.toLowerCase()) {
      case 'sunday': return DateTime.sunday;
      case 'monday': return DateTime.monday;
      case 'tuesday': return DateTime.tuesday;
      case 'wednesday': return DateTime.wednesday;
      case 'thursday': return DateTime.thursday;
      case 'friday': return DateTime.friday;
      case 'saturday': return DateTime.saturday;
      default: return -1; // Invalid
    }
  }
}
