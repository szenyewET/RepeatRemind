import '../models/category.dart';
import '../models/interval.dart';

/// A static preset definition used in the Browse Presets modal.
class PresetDefinition {
  final String name;
  final Category category;
  final IntervalType intervalType;
  final int intervalValue;

  const PresetDefinition({
    required this.name,
    required this.category,
    required this.intervalType,
    required this.intervalValue,
  });

  /// Human-readable interval summary, e.g. "Every 3 months".
  String get intervalSummary {
    final unit = intervalValue == 1
        ? intervalType.name.replaceAll('s', '') // "day", "week", "month"
        : intervalType.name; // "days", "weeks", "months"
    return 'Every $intervalValue $unit';
  }
}

/// Static library of built-in maintenance presets.
///
/// No persistence or I/O — pure in-memory data.
class PresetLibrary {
  const PresetLibrary._();

  static const List<PresetDefinition> presets = [
    // ── Car ────────────────────────────────────────────────────────────────
    PresetDefinition(
      name: 'Oil Change',
      category: Category.car,
      intervalType: IntervalType.months,
      intervalValue: 3,
    ),
    PresetDefinition(
      name: 'Tyre Rotation',
      category: Category.car,
      intervalType: IntervalType.months,
      intervalValue: 6,
    ),
    PresetDefinition(
      name: 'Car Wash',
      category: Category.car,
      intervalType: IntervalType.weeks,
      intervalValue: 2,
    ),
    PresetDefinition(
      name: 'Air Filter Replacement',
      category: Category.car,
      intervalType: IntervalType.months,
      intervalValue: 12,
    ),

    // ── Home ───────────────────────────────────────────────────────────────
    PresetDefinition(
      name: 'Vacuum',
      category: Category.home,
      intervalType: IntervalType.weeks,
      intervalValue: 1,
    ),
    PresetDefinition(
      name: 'Change HVAC Filter',
      category: Category.home,
      intervalType: IntervalType.months,
      intervalValue: 3,
    ),
    PresetDefinition(
      name: 'Test Smoke Alarm',
      category: Category.home,
      intervalType: IntervalType.months,
      intervalValue: 6,
    ),
    PresetDefinition(
      name: 'Clean Gutters',
      category: Category.home,
      intervalType: IntervalType.months,
      intervalValue: 6,
    ),

    // ── Pet ────────────────────────────────────────────────────────────────
    PresetDefinition(
      name: 'Flea Treatment',
      category: Category.pet,
      intervalType: IntervalType.months,
      intervalValue: 1,
    ),
    PresetDefinition(
      name: 'Vet Checkup',
      category: Category.pet,
      intervalType: IntervalType.months,
      intervalValue: 12,
    ),
    PresetDefinition(
      name: 'Grooming',
      category: Category.pet,
      intervalType: IntervalType.weeks,
      intervalValue: 6,
    ),
    PresetDefinition(
      name: 'Heartworm Prevention',
      category: Category.pet,
      intervalType: IntervalType.months,
      intervalValue: 1,
    ),

    // ── Health ─────────────────────────────────────────────────────────────
    PresetDefinition(
      name: 'Dental Checkup',
      category: Category.health,
      intervalType: IntervalType.months,
      intervalValue: 6,
    ),
    PresetDefinition(
      name: 'Eye Test',
      category: Category.health,
      intervalType: IntervalType.months,
      intervalValue: 12,
    ),
    PresetDefinition(
      name: 'Blood Pressure Check',
      category: Category.health,
      intervalType: IntervalType.months,
      intervalValue: 3,
    ),

    // ── Garden ─────────────────────────────────────────────────────────────
    PresetDefinition(
      name: 'Fertilise Lawn',
      category: Category.garden,
      intervalType: IntervalType.months,
      intervalValue: 2,
    ),
    PresetDefinition(
      name: 'Mow Lawn',
      category: Category.garden,
      intervalType: IntervalType.weeks,
      intervalValue: 2,
    ),
    PresetDefinition(
      name: 'Prune Shrubs',
      category: Category.garden,
      intervalType: IntervalType.months,
      intervalValue: 3,
    ),
  ];

  /// Returns all presets for [category], or all presets if [category] is null.
  static List<PresetDefinition> byCategory(Category? category) {
    if (category == null) return List.unmodifiable(presets);
    return presets.where((p) => p.category == category).toList();
  }
}
