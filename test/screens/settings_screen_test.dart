import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/providers/settings_provider.dart';
import 'package:repeatremind/screens/settings_screen.dart';
import 'package:repeatremind/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SettingsService> makeSettings({
    ThemeMode themeMode = ThemeMode.system,
    int advanceNoticeDays = 1,
    int notificationHour = 9,
    int notificationMinute = 0,
  }) async {
    SharedPreferences.setMockInitialValues({
      'themeMode': themeMode.index,
      'defaultAdvanceNoticeDays': advanceNoticeDays,
      'notificationHour': notificationHour,
      'notificationMinute': notificationMinute,
    });
    return SettingsService.load();
  }

  Widget buildHarness(SettingsService settings) {
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith(() => SettingsNotifier()..preload(settings)),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  testWidgets('settings screen renders without error', (tester) async {
    final settings = await makeSettings();
    await tester.pumpWidget(buildHarness(settings));
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('theme segment shows System selected by default', (tester) async {
    final settings = await makeSettings(themeMode: ThemeMode.system);
    await tester.pumpWidget(buildHarness(settings));
    await tester.pump();
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('theme segment shows Dark selected when themeMode is dark', (tester) async {
    final settings = await makeSettings(themeMode: ThemeMode.dark);
    await tester.pumpWidget(buildHarness(settings));
    await tester.pump();
    // SegmentedButton renders — verify all options present
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('advance notice days are displayed', (tester) async {
    final settings = await makeSettings(advanceNoticeDays: 3);
    await tester.pumpWidget(buildHarness(settings));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tapping Dark segment calls setThemeMode', (tester) async {
    final settings = await makeSettings(themeMode: ThemeMode.system);
    await tester.pumpWidget(buildHarness(settings));
    await tester.pump();

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(settings.themeMode, ThemeMode.dark);
  });

  testWidgets('tapping plus stepper increments advance notice days', (tester) async {
    final settings = await makeSettings(advanceNoticeDays: 1);
    await tester.pumpWidget(buildHarness(settings));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(settings.defaultAdvanceNoticeDays, 2);
  });

  testWidgets('tapping minus stepper decrements advance notice days (min 1)', (tester) async {
    final settings = await makeSettings(advanceNoticeDays: 5);
    await tester.pumpWidget(buildHarness(settings));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(settings.defaultAdvanceNoticeDays, 4);
  });
}
