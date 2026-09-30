import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';

/// Local reminder alerts + device registration for server/FCM pushes.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();
  static const _deviceIdKey = 'swaeq_device_id';
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _configureLocalTimezone();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Create notification channels first (non-blocking, no permission needed)
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'swaeq_reminders',
          'Reminders',
          description: 'Medicine, water, food and care reminders',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'swaeq_general',
          'Updates',
          description: 'Journey, doctor and account updates',
          importance: Importance.defaultImportance,
        ),
      );

      _ready = true;

      // Request permissions asynchronously AFTER marking ready.
      // This prevents blocking app startup if permission dialogs hang.
      _requestPermissionsAsync(androidPlugin);
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
      // Mark as ready anyway so app can continue without notifications
      _ready = true;
    }
  }

  /// Request notification permissions asynchronously without blocking startup.
  Future<void> _requestPermissionsAsync(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    try {
      // Small delay to let the UI render first
      await Future.delayed(const Duration(milliseconds: 500));

      if (Platform.isAndroid) {
        // Request notification permission
        try {
          final notif = await Permission.notification.status;
          if (!notif.isGranted) {
            await Permission.notification.request();
          }
        } catch (e) {
          debugPrint('Notification permission request failed: $e');
        }

        // Request exact alarm permission (Android 12+)
        try {
          final alarm = await Permission.scheduleExactAlarm.status;
          if (!alarm.isGranted) {
            await Permission.scheduleExactAlarm.request();
          }
        } catch (e) {
          debugPrint('Exact alarm permission request failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Permission requests failed: $e');
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final dynamic info = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('FlutterTimezone.getLocalTimezone() timed out');
          return 'Asia/Kolkata';
        },
      );
      final name = info is String
          ? info
          : (info.identifier as String? ?? info.toString());
      tz.setLocalLocation(tz.getLocation(name));
      debugPrint('Notifications timezone: $name');
    } catch (e) {
      debugPrint('Timezone fallback Asia/Kolkata ($e)');
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
  }

  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  Future<void> registerWithApi(ApiClient api, {String? pushToken}) async {
    try {
      await init();
      final id = await deviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';
      await api.registerDevice(
        deviceId: id,
        platform: platform,
        pushToken: pushToken,
      );
    } catch (e) {
      debugPrint('Device register skipped: $e');
    }
  }

  /// Pull reminder definitions from API and (re)schedule local notifications.
  Future<void> syncFromApi(ApiClient api) async {
    try {
      await init();
      final today = _todayIst();
      final data = await api.reminders(today);
      final defs = List<Map<String, dynamic>>.from(
        data['reminders'] as List? ?? [],
      );
      await syncReminders(defs);
    } catch (e) {
      debugPrint('Reminder sync skipped: $e');
    }
  }

  Future<void> syncReminders(List<Map<String, dynamic>> reminders) async {
    await init();
    await _plugin.cancelAll();
    var scheduled = 0;
    for (final r in reminders) {
      if (r['enabled'] == false) continue;
      scheduled += await scheduleReminder(r);
    }
    debugPrint('Scheduled $scheduled local reminder notification(s)');
  }

  /// Returns number of notification slots scheduled.
  Future<int> scheduleReminder(Map<String, dynamic> reminder) async {
    await init();
    final id = reminder['id']?.toString() ?? '';
    final title = reminder['title']?.toString() ?? 'Reminder';
    final body = reminder['subtitle']?.toString() ??
        'Time for your ${reminder['type'] ?? 'care'} reminder';
    final times = List<String>.from(
      (reminder['times'] as List?)?.map((e) => e.toString()) ?? const [],
    );
    final days = List<int>.from(
      (reminder['daysOfWeek'] as List?)?.map((e) => (e as num).toInt()) ??
          const [0, 1, 2, 3, 4, 5, 6],
    );
    if (id.isEmpty || times.isEmpty || days.isEmpty) return 0;

    var count = 0;
    for (final day in days) {
      for (final time in times) {
        final parts = time.split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final notifId = _notifId(id, day, time);
        final when = _nextInstance(day, hour, minute);
        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            'swaeq_reminders',
            'Reminders',
            channelDescription: 'Medicine, water, food and care reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(body),
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
        try {
          await _plugin.zonedSchedule(
            notifId,
            title,
            body,
            when,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'reminder:$id',
          );
          count++;
        } catch (e) {
          // Exact alarms denied → fall back so reminders still fire.
          debugPrint('Exact schedule failed ($e); trying inexact');
          try {
            await _plugin.zonedSchedule(
              notifId,
              title,
              body,
              when,
              details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              payload: 'reminder:$id',
            );
            count++;
          } catch (e2) {
            debugPrint('Failed to schedule reminder $id @ $time: $e2');
          }
        }
      }
    }
    return count;
  }

  Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'swaeq_general',
          'Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Fire a one-shot test notification in [seconds] (for field debugging).
  Future<void> scheduleTestIn({int seconds = 10}) async {
    await init();
    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      990001,
      'SwaEQ test reminder',
      'If you see this, local notifications are working.',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'swaeq_reminders',
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _notifId(String reminderId, int day, String time) {
    return Object.hash(reminderId, day, time) & 0x7fffffff;
  }

  String _todayIst() {
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// [day] is 0=Sunday … 6=Saturday (API convention).
  /// Dart [DateTime.weekday] is 1=Monday … 7=Sunday.
  tz.TZDateTime _nextInstance(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final dartWeekday = day == 0 ? DateTime.sunday : day;
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != dartWeekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        hour,
        minute,
      );
    }
    return scheduled;
  }
}
