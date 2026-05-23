import 'package:flutter_test/flutter_test.dart';

import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/services/preset_library.dart';

void main() {
  group('PresetLibrary', () {
    test('presets list has at least 15 items', () {
      expect(PresetLibrary.presets.length, greaterThanOrEqualTo(15));
    });

    test('Car category has at least 3 presets', () {
      final carPresets = PresetLibrary.presets
          .where((p) => p.category == Category.car)
          .toList();
      expect(carPresets.length, greaterThanOrEqualTo(3));
    });

    test('Home category has at least 3 presets', () {
      final homePresets = PresetLibrary.presets
          .where((p) => p.category == Category.home)
          .toList();
      expect(homePresets.length, greaterThanOrEqualTo(3));
    });

    test('Pet category has at least 3 presets', () {
      final petPresets = PresetLibrary.presets
          .where((p) => p.category == Category.pet)
          .toList();
      expect(petPresets.length, greaterThanOrEqualTo(3));
    });

    test('Health category has at least 3 presets', () {
      final healthPresets = PresetLibrary.presets
          .where((p) => p.category == Category.health)
          .toList();
      expect(healthPresets.length, greaterThanOrEqualTo(3));
    });

    test('Garden category has at least 3 presets', () {
      final gardenPresets = PresetLibrary.presets
          .where((p) => p.category == Category.garden)
          .toList();
      expect(gardenPresets.length, greaterThanOrEqualTo(3));
    });

    test('byCategory(Category.car) returns only car presets', () {
      final carPresets = PresetLibrary.byCategory(Category.car);
      expect(carPresets.every((p) => p.category == Category.car), isTrue);
    });

    test('byCategory(Category.home) returns only home presets', () {
      final homePresets = PresetLibrary.byCategory(Category.home);
      expect(homePresets.every((p) => p.category == Category.home), isTrue);
    });

    test('byCategory returns all presets when null is passed', () {
      final all = PresetLibrary.byCategory(null);
      expect(all.length, equals(PresetLibrary.presets.length));
    });

    test('all presets have intervalValue > 0', () {
      for (final preset in PresetLibrary.presets) {
        expect(preset.intervalValue, greaterThan(0),
            reason: '${preset.name} has intervalValue <= 0');
      }
    });

    test('no preset has an empty name', () {
      for (final preset in PresetLibrary.presets) {
        expect(preset.name.trim(), isNotEmpty,
            reason: 'Found a preset with an empty name');
      }
    });
  });
}
