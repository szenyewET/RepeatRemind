import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'category.dart';
import 'interval.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final Category category;

  @HiveField(3)
  final Interval interval;

  @HiveField(4)
  final DateTime nextDueDate;

  @HiveField(5)
  final int advanceNoticeDays;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final List<DateTime> completionHistory;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final int notificationId;

  factory Task({
    String? id,
    required String name,
    required Category category,
    required Interval interval,
    required DateTime nextDueDate,
    int advanceNoticeDays = 1,
    String? notes,
    List<DateTime>? completionHistory,
    DateTime? createdAt,
    int? notificationId,
  }) {
    final resolvedId = id ?? const Uuid().v4();
    return Task._internal(
      id: resolvedId,
      name: name,
      category: category,
      interval: interval,
      nextDueDate: nextDueDate,
      advanceNoticeDays: advanceNoticeDays,
      notes: notes,
      completionHistory: completionHistory ?? [],
      createdAt: createdAt ?? DateTime.now(),
      notificationId: notificationId ??
          int.parse(resolvedId.replaceAll('-', '').substring(0, 8), radix: 16) &
              0x7FFFFFFF,
    );
  }

  Task._internal({
    required this.id,
    required this.name,
    required this.category,
    required this.interval,
    required this.nextDueDate,
    required this.advanceNoticeDays,
    this.notes,
    required this.completionHistory,
    required this.createdAt,
    required this.notificationId,
  });

  Task copyWith({
    String? name,
    Category? category,
    Interval? interval,
    DateTime? nextDueDate,
    int? advanceNoticeDays,
    String? notes,
    List<DateTime>? completionHistory,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      interval: interval ?? this.interval,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      advanceNoticeDays: advanceNoticeDays ?? this.advanceNoticeDays,
      notes: notes ?? this.notes,
      completionHistory: completionHistory ?? this.completionHistory,
      createdAt: createdAt,
    );
  }

  Task completing(DateTime confirmedNextDueDate) => copyWith(
        nextDueDate: confirmedNextDueDate,
        completionHistory: [...completionHistory, DateTime.now()],
      );
}
