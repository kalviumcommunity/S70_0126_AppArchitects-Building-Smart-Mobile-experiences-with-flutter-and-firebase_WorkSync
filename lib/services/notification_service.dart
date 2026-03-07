import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Channel details
  static const _deadlineChannel = AndroidNotificationDetails(
    'deadlines_today_channel',
    'Deadlines Today',
    channelDescription: 'Alerts when you have tasks due today',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    styleInformation: BigTextStyleInformation(''),
  );

  static const _dueChannel = AndroidNotificationDetails(
    'due_channel',
    'Task Due Reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings: initSettings);
    tzdata.initializeTimeZones();

    // Use local timezone
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    // Request permissions for Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Fire an immediate notification summarising today's deadlines.
  Future<void> showDeadlinesToday(List<String> taskTitles) async {
    if (taskTitles.isEmpty) return;

    final body = taskTitles.length == 1
        ? '"${taskTitles.first}" is due today!'
        : '${taskTitles.length} tasks are due today:\n${taskTitles.map((t) => '• $t').join('\n')}';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'deadlines_today_channel',
        'Deadlines Today',
        channelDescription: 'Alerts when you have tasks due today',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    await _plugin.show(
      id: 0,
      title: '📋 Deadlines Today',
      body: body,
      notificationDetails: details,
    );
  }

  /// Schedule a future due-date reminder.
  Future<void> scheduleDueReminder({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(android: _dueChannel);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}

