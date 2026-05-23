import 'task.dart';

const _dueSoonWindowDays = 7;

class TaskSections {
  final List<Task> overdue;
  final List<Task> dueSoon;
  final List<Task> upcoming;

  const TaskSections({
    required this.overdue,
    required this.dueSoon,
    required this.upcoming,
  });

  static TaskSections from(List<Task> tasks, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final windowEnd = today.add(const Duration(days: _dueSoonWindowDays));

    final overdue = <Task>[];
    final dueSoon = <Task>[];
    final upcoming = <Task>[];

    for (final task in tasks) {
      final due = DateTime(
        task.nextDueDate.year,
        task.nextDueDate.month,
        task.nextDueDate.day,
      );
      if (due.isBefore(today)) {
        overdue.add(task);
      } else if (!due.isAfter(windowEnd)) {
        dueSoon.add(task);
      } else {
        upcoming.add(task);
      }
    }

    int byDueDate(Task a, Task b) => a.nextDueDate.compareTo(b.nextDueDate);

    return TaskSections(
      overdue: overdue..sort(byDueDate),
      dueSoon: dueSoon..sort(byDueDate),
      upcoming: upcoming..sort(byDueDate),
    );
  }
}
