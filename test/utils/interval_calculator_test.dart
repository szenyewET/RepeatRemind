import 'package:flutter_test/flutter_test.dart';
import 'package:repeatremind/models/interval.dart';
import 'package:repeatremind/utils/interval_calculator.dart';

void main() {
  const calc = IntervalCalculator();

  group('nextDueDate — days', () {
    test('adds exact days', () {
      final result = calc.nextDueDate(
        DateTime(2025, 1, 1),
        const Interval(type: IntervalType.days, value: 10),
      );
      expect(result, DateTime(2025, 1, 11));
    });

    test('interval of 1 day', () {
      final result = calc.nextDueDate(
        DateTime(2025, 3, 31),
        const Interval(type: IntervalType.days, value: 1),
      );
      expect(result, DateTime(2025, 4, 1));
    });
  });

  group('nextDueDate — weeks', () {
    test('adds exact weeks as days', () {
      final result = calc.nextDueDate(
        DateTime(2025, 1, 1),
        const Interval(type: IntervalType.weeks, value: 2),
      );
      expect(result, DateTime(2025, 1, 15));
    });
  });

  group('nextDueDate — months', () {
    test('standard month addition', () {
      final result = calc.nextDueDate(
        DateTime(2025, 1, 15),
        const Interval(type: IntervalType.months, value: 3),
      );
      expect(result, DateTime(2025, 4, 15));
    });

    test('Feb 28 + 1 month = Mar 28, not Mar 31 or overflow', () {
      final result = calc.nextDueDate(
        DateTime(2025, 2, 28),
        const Interval(type: IntervalType.months, value: 1),
      );
      expect(result, DateTime(2025, 3, 28));
    });

    test('Jan 31 + 1 month clamps to Feb 28 (non-leap year)', () {
      final result = calc.nextDueDate(
        DateTime(2025, 1, 31),
        const Interval(type: IntervalType.months, value: 1),
      );
      expect(result, DateTime(2025, 2, 28));
    });

    test('Jan 31 + 1 month clamps to Feb 29 (leap year 2024)', () {
      final result = calc.nextDueDate(
        DateTime(2024, 1, 31),
        const Interval(type: IntervalType.months, value: 1),
      );
      expect(result, DateTime(2024, 2, 29));
    });

    test('Dec + 1 month rolls over to next year', () {
      final result = calc.nextDueDate(
        DateTime(2025, 12, 15),
        const Interval(type: IntervalType.months, value: 1),
      );
      expect(result, DateTime(2026, 1, 15));
    });

    test('multi-month spanning year boundary', () {
      final result = calc.nextDueDate(
        DateTime(2025, 11, 30),
        const Interval(type: IntervalType.months, value: 3),
      );
      expect(result, DateTime(2026, 2, 28));
    });
  });

  group('notifyAt', () {
    test('returns ideal time when advance notice fits', () {
      final nextDue = DateTime.now().add(const Duration(days: 30));
      final result = calc.notifyAt(nextDue, 7);
      expect(result, nextDue.subtract(const Duration(days: 7)));
    });

    test('clamps to now + 1 hour when advance notice exceeds interval', () {
      final nextDue = DateTime.now().add(const Duration(days: 2));
      final result = calc.notifyAt(nextDue, 7);
      final earliest = DateTime.now().add(const Duration(hours: 1));
      expect(result.isAfter(earliest.subtract(const Duration(seconds: 5))), isTrue);
      expect(result.isBefore(earliest.add(const Duration(seconds: 5))), isTrue);
    });

    test('0 advance days fires on due date', () {
      final nextDue = DateTime.now().add(const Duration(days: 30));
      final result = calc.notifyAt(nextDue, 0);
      expect(result, nextDue);
    });
  });
}
