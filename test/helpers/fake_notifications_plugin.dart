import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<int> cancelledIds = [];
  final List<({int id, DateTime notifyAt})> scheduled = [];

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required UILocalNotificationDateInterpretation
        uiLocalNotificationDateInterpretation,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add((id: id, notifyAt: scheduledDate.toLocal()));
  }

  @override
  Future<bool?> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
    return true;
  }
}
