import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Minimal local notification service to schedule a single due-date reminder
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    // In v20+, initialize takes settings as a named argument.
    await _plugin.initialize(settings: initSettings);
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  Future<void> scheduleDueReminder({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'due_channel',
      'Task Due Reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    
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
