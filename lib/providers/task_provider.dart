import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/task_sections.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/task_repository.dart';
import '../utils/interval_calculator.dart';

// Overridden in main() with the initialized plugin instance.
final notificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>(
  (_) => throw UnimplementedError('notificationsPluginProvider must be overridden in main()'),
);

final intervalCalculatorProvider = Provider<IntervalCalculator>(
  (_) => const IntervalCalculator(),
);

final databaseServiceProvider = Provider<DatabaseService>(
  (_) => DatabaseService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.read(notificationsPluginProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(
    db: ref.read(databaseServiceProvider),
    notifications: ref.read(notificationServiceProvider),
    calculator: ref.read(intervalCalculatorProvider),
  ),
);

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    return ref.read(taskRepositoryProvider).getAll();
  }

  Future<void> add(Task task) async {
    final previous = state;
    state = AsyncData([...?state.value, task]);
    try {
      await ref.read(taskRepositoryProvider).add(task);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> commitCompletion(Task task, DateTime confirmedNextDueDate) async {
    final previous = state;
    state = AsyncData(
      state.value!.map((t) => t.id == task.id ? task.completing(confirmedNextDueDate) : t).toList(),
    );
    try {
      final confirmed = await ref.read(taskRepositoryProvider).commitCompletion(task, confirmedNextDueDate);
      state = AsyncData(
        state.value!.map((t) => t.id == task.id ? confirmed : t).toList(),
      );
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  // Renamed from 'update' to avoid conflict with AsyncNotifier.update.
  Future<void> edit(Task task) async {
    final previous = state;
    state = AsyncData(
      state.value!.map((t) => t.id == task.id ? task : t).toList(),
    );
    try {
      await ref.read(taskRepositoryProvider).update(task);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> delete(Task task) async {
    final previous = state;
    state = AsyncData(
      state.value!.where((t) => t.id != task.id).toList(),
    );
    try {
      await ref.read(taskRepositoryProvider).delete(task);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

final taskSectionsProvider = Provider<AsyncValue<TaskSections>>((ref) {
  return ref.watch(taskListProvider).whenData(
    (tasks) => TaskSections.from(tasks, DateTime.now()),
  );
});
