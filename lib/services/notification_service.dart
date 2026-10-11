import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/class_session.dart';

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;

      final etcName = offsetHours <= 0
          ? 'Etc/GMT+${-offsetHours}'
          : 'Etc/GMT-$offsetHours';

      tz.setLocalLocation(
        tz.getLocation(etcName),
      );
    } catch (e) {
      tz.setLocalLocation(tz.UTC);

      debugPrint(
        'Failed to set local timezone. Falling back to UTC: $e',
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
    );

    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // Generic remote FCM notification shown while app is open.
  static Future<void> showRemoteAlert({
    required String title,
    required String message,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'class_updates',
        'Class Updates',
        channelDescription:
        'Class timetable updates and lecturer announcements',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      notificationDetails: details,
    );
  }

  // Used for local class update messages if needed.
  static Future<void> showClassUpdate({
    required String title,
    required String message,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'class_alerts',
        'Class Alerts',
        channelDescription:
        'Alerts for cancelled, rescheduled or updated classes',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      notificationDetails: details,
    );
  }

  static int _reminderIdFor(
      String classId,
      ) {
    return classId.hashCode.abs() % 2147483647;
  }

  static Future<void> cancelClassReminder(
      String classId,
      ) async {
    await _plugin.cancel(
      id: _reminderIdFor(classId),
    );
  }

  static Future<void> scheduleSingleClassReminder(
      ClassSession session,
      int minutesBefore,
      ) async {
    final int id = _reminderIdFor(
      session.id,
    );

    final tz.TZDateTime? scheduledTime =
    _nextOccurrence(
      session.day,
      session.startTime,
      minutesBefore,
    );

    if (scheduledTime == null) {
      await _plugin.cancel(
        id: id,
      );

      return;
    }

    final String body =
    session.classType == 'online'
        ? '${session.courseName} starts at '
        '${session.startTime} and ends at '
        '${session.endTime} online.'
        : '${session.courseName} starts at '
        '${session.startTime} and ends at '
        '${session.endTime} in ${session.room}.';

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Upcoming Class',
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails:
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'class_reminders',
            'Class Reminders',
            channelDescription:
            'Reminders before your scheduled classes',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
        DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint(
        'Failed to schedule reminder for '
            '${session.courseName}: $e',
      );
    }
  }

  static Future<void> scheduleClassReminders(
      List<ClassSession> classes,
      int minutesBefore,
      ) async {
    for (final session in classes) {
      await scheduleSingleClassReminder(
        session,
        minutesBefore,
      );
    }
  }

  static tz.TZDateTime? _nextOccurrence(
      String day,
      String time,
      int minutesBefore,
      ) {
    final regex = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    );

    final match = regex.firstMatch(
      time.trim(),
    );

    if (match == null) {
      return null;
    }

    int hour = int.parse(
      match.group(1)!,
    );

    final minute = int.parse(
      match.group(2)!,
    );

    final period =
    match.group(3)!.toUpperCase();

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    final targetWeekday =
        _weekdayNames.indexOf(day) + 1;

    if (targetWeekday == 0) {
      return null;
    }

    final now =
    tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).subtract(
      Duration(
        minutes: minutesBefore,
      ),
    );

    while (
    scheduled.weekday != targetWeekday ||
        scheduled.isBefore(now)) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    return scheduled;
  }
}