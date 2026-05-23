import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class DatabaseService {
  static const _boxName = 'tasks';

  Box<Task> get _box => Hive.box<Task>(_boxName);

  List<Task> getAll() => _box.values.toList();

  Future<void> save(Task task) => _box.put(task.id, task);

  Future<void> delete(String id) => _box.delete(id);
}
