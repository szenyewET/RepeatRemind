import '../models/task.dart';
import '../utils/interval_calculator.dart';
import 'database_service.dart';
import 'notification_service.dart';

class TaskRepository {
  final DatabaseService _db;
  final NotificationService _notifications;
  final IntervalCalculator _calculator;

  TaskRepository({
    required DatabaseService db,
    required NotificationService notifications,
    IntervalCalculator calculator = const IntervalCalculator(),
  })  : _db = db,
        _notifications = notifications,
        _calculator = calculator;

  List<Task> getAll() => _db.getAll();

  Future<Task> add(Task task) async {
    final notify = _calculator.notifyAt(task.nextDueDate, task.advanceNoticeDays);
    await _scheduleFor(task, notify);
    await _db.save(task);
    return task;
  }

  Future<Task> update(Task task) async {
    await _notifications.cancel(task.notificationId);
    final notify = _calculator.notifyAt(task.nextDueDate, task.advanceNoticeDays);
    await _scheduleFor(task, notify);
    await _db.save(task);
    return task;
  }

  // Returns the calculated nextDueDate for preview in the Mark as Done dialog.
  // Pass the result (or user-adjusted value) to commitCompletion.
  DateTime previewNextDueDate(Task task, DateTime completionDate) =>
      _calculator.nextDueDate(completionDate, task.interval);

  // Accepts the nextDueDate already confirmed (and optionally adjusted) by the user.
  Future<Task> commitCompletion(Task task, DateTime confirmedNextDueDate) async {
    final updated = task.completing(confirmedNextDueDate);
    await _notifications.cancel(task.notificationId);
    final notify = _calculator.notifyAt(confirmedNextDueDate, updated.advanceNoticeDays);
    await _scheduleFor(updated, notify);
    await _db.save(updated);
    return updated;
  }

  Future<void> delete(Task task) async {
    await _notifications.cancel(task.notificationId);
    await _db.delete(task.id);
  }

  // Called on app open to handle reinstall and device restart.
  Future<void> rescheduleAll() async {
    for (final task in _db.getAll()) {
      await _notifications.cancel(task.notificationId);
      final notify = _calculator.notifyAt(task.nextDueDate, task.advanceNoticeDays);
      await _scheduleFor(task, notify);
    }
  }

  Future<void> _scheduleFor(Task task, DateTime notifyAt) {
    final daysUntil = task.nextDueDate.difference(notifyAt).inDays.clamp(0, 9999);
    final body = daysUntil == 0 ? 'Due today' : 'Due in $daysUntil days';
    return _notifications.schedule(
      task.notificationId,
      '${task.name} (${task.category.name})',
      body,
      notifyAt,
      payload: task.id,
    );
  }
}
