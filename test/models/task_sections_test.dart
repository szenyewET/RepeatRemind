import 'package:flutter_test/flutter_test.dart';
import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart';
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/models/task_sections.dart';

void main() {
  // Fixed now with a time component — confirms date comparison ignores time.
  final now = DateTime(2026, 5, 23, 10, 30);
  final today = DateTime(2026, 5, 23);

  Task task(DateTime nextDueDate) => Task(
        name: 'Test',
        category: Category.home,
        interval: const Interval(type: IntervalType.days, value: 7),
        nextDueDate: nextDueDate,
      );

  test('empty list → all sections empty', () {
    final s = TaskSections.from([], now);
    expect(s.overdue, isEmpty);
    expect(s.dueSoon, isEmpty);
    expect(s.upcoming, isEmpty);
  });

  group('overdue', () {
    test('task due yesterday → overdue', () {
      final s = TaskSections.from(
        [task(today.subtract(const Duration(days: 1)))],
        now,
      );
      expect(s.overdue, hasLength(1));
      expect(s.dueSoon, isEmpty);
      expect(s.upcoming, isEmpty);
    });

    test('task due last week → overdue', () {
      final s = TaskSections.from(
        [task(today.subtract(const Duration(days: 10)))],
        now,
      );
      expect(s.overdue, hasLength(1));
    });

    test('overdue sorted oldest first', () {
      final older = task(today.subtract(const Duration(days: 5)));
      final newer = task(today.subtract(const Duration(days: 1)));
      final s = TaskSections.from([newer, older], now);
      expect(s.overdue.first.nextDueDate, older.nextDueDate);
      expect(s.overdue.last.nextDueDate, newer.nextDueDate);
    });
  });

  group('dueSoon', () {
    test('task due today → dueSoon not overdue', () {
      final s = TaskSections.from([task(today)], now);
      expect(s.dueSoon, hasLength(1));
      expect(s.overdue, isEmpty);
    });

    test('task due today with earlier time → dueSoon not overdue', () {
      // Date comparison must ignore the time component.
      final s = TaskSections.from(
        [task(DateTime(2026, 5, 23, 8, 0))],
        now,
      );
      expect(s.dueSoon, hasLength(1));
      expect(s.overdue, isEmpty);
    });

    test('task due in 1 day → dueSoon', () {
      final s = TaskSections.from(
        [task(today.add(const Duration(days: 1)))],
        now,
      );
      expect(s.dueSoon, hasLength(1));
    });

    test('task due in exactly 7 days → dueSoon', () {
      final s = TaskSections.from(
        [task(today.add(const Duration(days: 7)))],
        now,
      );
      expect(s.dueSoon, hasLength(1));
      expect(s.upcoming, isEmpty);
    });

    test('dueSoon sorted soonest first', () {
      final sooner = task(today.add(const Duration(days: 2)));
      final later = task(today.add(const Duration(days: 5)));
      final s = TaskSections.from([later, sooner], now);
      expect(s.dueSoon.first.nextDueDate, sooner.nextDueDate);
      expect(s.dueSoon.last.nextDueDate, later.nextDueDate);
    });
  });

  group('upcoming', () {
    test('task due in 8 days → upcoming not dueSoon', () {
      final s = TaskSections.from(
        [task(today.add(const Duration(days: 8)))],
        now,
      );
      expect(s.upcoming, hasLength(1));
      expect(s.dueSoon, isEmpty);
    });

    test('upcoming sorted soonest first', () {
      final sooner = task(today.add(const Duration(days: 10)));
      final later = task(today.add(const Duration(days: 20)));
      final s = TaskSections.from([later, sooner], now);
      expect(s.upcoming.first.nextDueDate, sooner.nextDueDate);
    });
  });

  test('tasks spread across all three sections', () {
    final tasks = [
      task(today.subtract(const Duration(days: 2))), // overdue
      task(today),                                    // dueSoon (today)
      task(today.add(const Duration(days: 3))),       // dueSoon
      task(today.add(const Duration(days: 10))),      // upcoming
    ];
    final s = TaskSections.from(tasks, now);
    expect(s.overdue, hasLength(1));
    expect(s.dueSoon, hasLength(2));
    expect(s.upcoming, hasLength(1));
  });
}
