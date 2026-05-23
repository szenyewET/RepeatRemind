import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart';
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/services/database_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_db_test_');
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

  Task makeTask({String name = 'Oil Change'}) => Task(
        name: name,
        category: Category.car,
        interval: const Interval(type: IntervalType.months, value: 3),
        nextDueDate: DateTime(2026, 8, 1),
      );

  group('DatabaseService (in-memory box)', () {
    late DatabaseService svc;

    setUp(() {
      svc = DatabaseService();
    });

    test('save a task → getAll() returns it', () async {
      final task = makeTask();
      await svc.save(task);
      final all = svc.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, task.id);
      expect(all.first.name, task.name);
    });

    test('delete a task → getAll() is empty', () async {
      final task = makeTask();
      await svc.save(task);
      await svc.delete(task.id);
      expect(svc.getAll(), isEmpty);
    });

    test('save updated task (same id) → getAll() returns updated version',
        () async {
      final task = makeTask(name: 'Original');
      await svc.save(task);
      final updated = task.copyWith(name: 'Updated');
      await svc.save(updated);
      final all = svc.getAll();
      expect(all, hasLength(1));
      expect(all.first.name, 'Updated');
    });
  });
}
