import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/notificationsGlobal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

const int _kMaintenanceNotificationIdBase = 2000;
const int _kMaintenanceNotificationIdMax = 2999;

const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
  'applianceMaintenance',
  'Appliance Maintenance',
  channelDescription: 'Reminders for scheduled appliance maintenance tasks',
  importance: Importance.defaultImportance,
  priority: Priority.defaultPriority,
);

const NotificationDetails _notificationDetails =
    NotificationDetails(android: _androidDetails);

/// Calculates the next due date from the last maintained date and interval.
DateTime calculateNextDueDate(
    DateTime lastMaintained, int intervalValue, MaintenanceIntervalUnit unit) {
  switch (unit) {
    case MaintenanceIntervalUnit.days:
      return lastMaintained.add(Duration(days: intervalValue));
    case MaintenanceIntervalUnit.weeks:
      return lastMaintained.add(Duration(days: intervalValue * 7));
    case MaintenanceIntervalUnit.months:
      return DateTime(
        lastMaintained.year,
        lastMaintained.month + intervalValue,
        lastMaintained.day,
      );
    case MaintenanceIntervalUnit.years:
      return DateTime(
        lastMaintained.year + intervalValue,
        lastMaintained.month,
        lastMaintained.day,
      );
  }
}

/// Cancels all scheduled maintenance notifications (IDs 2000–2999).
Future<void> cancelMaintenanceNotifications() async {
  if (kIsWeb) return;
  for (int i = _kMaintenanceNotificationIdBase;
      i <= _kMaintenanceNotificationIdMax;
      i++) {
    await flutterLocalNotificationsPlugin.cancel(i);
  }
}

/// Reschedules all maintenance notifications from the database.
/// Safe to call on startup and after any task is updated.
Future<void> scheduleMaintenanceNotifications() async {
  if (kIsWeb) return;
  await cancelMaintenanceNotifications();

  final List<MaintenanceTask> tasks =
      await database.getAllMaintenanceTasksDue();

  final now = DateTime.now();
  int idOffset = 0;

  for (final task in tasks) {
    if (idOffset > (_kMaintenanceNotificationIdMax -
        _kMaintenanceNotificationIdBase)) break;

    final DateTime? due = task.nextDueDate;
    if (due == null) continue;
    if (due.isBefore(now)) continue;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        _kMaintenanceNotificationIdBase + idOffset,
        'Maintenance Due',
        task.taskName,
        tz.TZDateTime.from(due, tz.local),
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'maintenanceTask?taskPk=${task.taskPk}',
      );
      idOffset++;
    } catch (e) {
      print('maintenanceNotifications: schedule error — $e');
    }
  }
}
