import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService defaults', () {
    test('themeMode defaults to ThemeMode.system', () async {
      final svc = await SettingsService.load();
      expect(svc.themeMode, ThemeMode.system);
    });

    test('defaultAdvanceNoticeDays defaults to 1', () async {
      final svc = await SettingsService.load();
      expect(svc.defaultAdvanceNoticeDays, 1);
    });

    test('notificationHour defaults to 9', () async {
      final svc = await SettingsService.load();
      expect(svc.notificationHour, 9);
    });

    test('notificationMinute defaults to 0', () async {
      final svc = await SettingsService.load();
      expect(svc.notificationMinute, 0);
    });
  });

  group('SettingsService setters', () {
    test('setThemeMode(dark) → getter returns ThemeMode.dark', () async {
      final svc = await SettingsService.load();
      await svc.setThemeMode(ThemeMode.dark);
      expect(svc.themeMode, ThemeMode.dark);
    });

    test('setThemeMode(light) → getter returns ThemeMode.light', () async {
      final svc = await SettingsService.load();
      await svc.setThemeMode(ThemeMode.light);
      expect(svc.themeMode, ThemeMode.light);
    });

    test('setDefaultAdvanceNoticeDays(7) → getter returns 7', () async {
      final svc = await SettingsService.load();
      await svc.setDefaultAdvanceNoticeDays(7);
      expect(svc.defaultAdvanceNoticeDays, 7);
    });

    test('setNotificationTime → notificationHour and notificationMinute updated', () async {
      final svc = await SettingsService.load();
      await svc.setNotificationTime(hour: 8, minute: 30);
      expect(svc.notificationHour, 8);
      expect(svc.notificationMinute, 30);
    });
  });

  group('SettingsService persistence', () {
    test('persists themeMode across loads', () async {
      final svc1 = await SettingsService.load();
      await svc1.setThemeMode(ThemeMode.dark);

      final svc2 = await SettingsService.load();
      expect(svc2.themeMode, ThemeMode.dark);
    });

    test('persists defaultAdvanceNoticeDays across loads', () async {
      final svc1 = await SettingsService.load();
      await svc1.setDefaultAdvanceNoticeDays(14);

      final svc2 = await SettingsService.load();
      expect(svc2.defaultAdvanceNoticeDays, 14);
    });
  });
}
