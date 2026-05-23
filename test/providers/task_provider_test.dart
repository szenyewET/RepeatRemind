import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart';
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/services/database_service.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../helpers/fake_notifications_plugin.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tz.initializeTimeZones();
    tempDir = await Directory.systemTemp.createTemp('hive_provider_test_');
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

  late FakeNotificationsPlugin fakePlugin;
  late DatabaseService db;
  late ProviderContainer container;

  setUp(() async {
    if (!Hive.isBoxOpen('tasks')) {
      await Hive.openBox<Task>('tasks');
    }
    fakePlugin = FakeNotificationsPlugin();
    db = DatabaseService();

    container = ProviderContainer(
      overrides: [
        notificationsPluginProvider.overrideWithValue(fakePlugin),
        databaseServiceProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    if (Hive.isBoxOpen('tasks')) {
      await Hive.box<Task>('tasks').clear();
      await Hive.box<Task>('tasks').close();
    }
    await Hive.deleteBoxFromDisk('tasks');
  });

  Task makeTask({String name = 'Oil Change'}) => Task(
        name: name,
        category: Category.car,
        interval: const Interval(type: IntervalType.months, value: 3),
        nextDueDate: DateTime.now().add(const Duration(days: 30)),
      );

  Future<List<Task>> readState() => container.read(taskListProvider.future);

  group('TaskListNotifier', () {
    test('add(task) → taskListProvider state contains the task', () async {
      await container.read(taskListProvider.future);
      final task = makeTask();
      await container.read(taskListProvider.notifier).add(task);
      final tasks = await readState();
      expect(tasks.any((t) => t.id == task.id), isTrue);
    });

    test(
        'commitCompletion(task, newDate) → task in state has updated nextDueDate',
        () async {
      await container.read(taskListProvider.future);
      final task = makeTask();
      await container.read(taskListProvider.notifier).add(task);

      final newDate = DateTime.now().add(const Duration(days: 60));
      await container
          .read(taskListProvider.notifier)
          .commitCompletion(task, newDate);

      final tasks = await readState();
      final updated = tasks.firstWhere((t) => t.id == task.id);
      expect(
        updated.nextDueDate.difference(newDate).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('delete(task) → task removed from taskListProvider state', () async {
      await container.read(taskListProvider.future);
      final task = makeTask();
      await container.read(taskListProvider.notifier).add(task);

      await container.read(taskListProvider.notifier).delete(task);

      final tasks = await readState();
      expect(tasks.any((t) => t.id == task.id), isFalse);
    });
  });
}
