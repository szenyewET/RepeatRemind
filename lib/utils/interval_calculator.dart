import '../models/interval.dart';

class IntervalCalculator {
  const IntervalCalculator();

  DateTime nextDueDate(DateTime completionDate, Interval interval) {
    return switch (interval.type) {
      IntervalType.days => completionDate.add(Duration(days: interval.value)),
      IntervalType.weeks => completionDate.add(Duration(days: interval.value * 7)),
      IntervalType.months => _addMonths(completionDate, interval.value),
    };
  }

  // Clamped to now + 1 hour so a notification is never scheduled in the past.
  DateTime notifyAt(DateTime nextDueDate, int advanceNoticeDays) {
    final ideal = nextDueDate.subtract(Duration(days: advanceNoticeDays));
    final earliest = DateTime.now().add(const Duration(hours: 1));
    return ideal.isAfter(earliest) ? ideal : earliest;
  }

  // Clamps day to last day of target month (Feb 28 + 1 month = Mar 28, not Mar 3).
  DateTime _addMonths(DateTime date, int months) {
    final rawMonth = date.month + months;
    final year = date.year + (rawMonth - 1) ~/ 12;
    final month = ((rawMonth - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day.clamp(1, lastDay);
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }
}
