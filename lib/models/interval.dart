import 'package:hive/hive.dart';

part 'interval.g.dart';

@HiveType(typeId: 2)
enum IntervalType {
  @HiveField(0)
  days,
  @HiveField(1)
  weeks,
  @HiveField(2)
  months,
  // km added Phase 2 — adding it here forces all switch sites to handle it
}

@HiveType(typeId: 3)
class Interval {
  @HiveField(0)
  final IntervalType type;

  @HiveField(1)
  final int value;

  const Interval({required this.type, required this.value});

  @override
  bool operator ==(Object other) =>
      other is Interval && type == other.type && value == other.value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => '$value ${type.name}';
}
