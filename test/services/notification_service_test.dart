import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart';
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/services/database_service.dart';
import 'package:repeatremind/services/notification_service.dart';
import 'package:repeatremind/services/task_repository.dart';
import 'package:repeatremind/utils/interval_calculator.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../helpers/fake_notifications_plugin.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tz.initializeTimeZones();
    tempDir = await Directory.systemTemp.createTemp('hive_notif_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(IntervalTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(IntervalAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    if (!Hive.isBoxOpen('tasks')) {
      await Hive.openBox<Task>('tasks');
    }
  });

  tearDown(() async {
    if (Hive.isBoxOpen('tasks')) {
      await Hive.box<Task>('tasks').clear();
      await Hive.box<Task>('tasks').close();
    }
    await Hive.deleteBoxFromDisk('tasks');
  });

  Task makeTask({int advanceNoticeDays = 3}) => Task(
        name: 'Tyre Rotation',
        category: Category.car,
        interval: const Interval(type: IntervalType.months, value: 6),
        nextDueDate: DateTime.now().add(const Duration(days: 30)),
        advanceNoticeDays: advanceNoticeDays,
      );

  group('NotificationService', () {
    test('schedule() is called with correct notifyAt', () async {
      final fake = FakeNotificationsPlugin();
      final svc = NotificationService(fake);
      final task = makeTask(advanceNoticeDays: 5);
      const calculator = IntervalCalculator();
      final expectedNotifyAt =
          calculator.notifyAt(task.nextDueDate, task.advanceNoticeDays);

      await svc.schedule(
        task.notificationId,
        task.name,
        'body',
        expectedNotifyAt,
        payload: task.id,
      );

      expect(fake.scheduled, hasLength(1));
      expect(fake.scheduled.first.id, task.notificationId);
      expect(
        fake.scheduled.first.notifyAt
            .difference(expectedNotifyAt)
            .inSeconds
            .abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('cancel() is called with the correct notification ID', () async {
      final fake = FakeNotificationsPlugin();
      final svc = NotificationService(fake);
      final task = makeTask();

      await svc.cancel(task.notificationId);

      expect(fake.cancelledIds, contains(task.notificationId));
    });
  });

  group('TaskRepository.rescheduleAll()', () {
    test('cancel is called before schedule for each task', () async {
      final fake = FakeNotificationsPlugin();
      final db = DatabaseService();
      final repo = TaskRepository(
        db: db,
        notifications: NotificationService(fake),
      );

      final task1 = makeTask();
      final task2 = Task(
        name: 'HVAC Filter',
        category: Category.home,
        interval: const Interval(type: IntervalType.months, value: 3),
        nextDueDate: DateTime.now().add(const Duration(days: 20)),
        advanceNoticeDays: 2,
      );

      await db.save(task1);
      await db.save(task2);

      fake.cancelledIds.clear();
      fake.scheduled.clear();

      await repo.rescheduleAll();

      expect(fake.cancelledIds,
          containsAll([task1.notificationId, task2.notificationId]));
      expect(fake.scheduled.map((e) => e.id),
          containsAll([task1.notificationId, task2.notificationId]));
      expect(fake.cancelledIds, hasLength(2));
      expect(fake.scheduled, hasLength(2));
    });
  });
}
