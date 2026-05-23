import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/settings_provider.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/screens/add_task_screen.dart';
import 'package:repeatremind/services/preset_library.dart';
import 'package:repeatremind/services/settings_service.dart';

// ── Fake TaskListNotifier (same pattern as add_task_screen_test.dart) ──────

class FakeTaskListNotifier extends AsyncNotifier<List<Task>>
    implements TaskListNotifier {
  final List<Task> addedTasks = [];

  @override
  Future<List<Task>> build() async => [];

  @override
  Future<void> add(Task task) async {
    addedTasks.add(task);
    state = AsyncData([...?state.value, task]);
  }

  @override
  Future<void> commitCompletion(Task task, DateTime confirmedNextDueDate) async {}

  @override
  Future<void> edit(Task task) async {}

  @override
  Future<void> delete(Task task) async {}
}

// ── Helpers ────────────────────────────────────────────────────────────────

Future<SettingsService> makeSettings({int advanceNoticeDays = 1}) async {
  SharedPreferences.setMockInitialValues({
    'defaultAdvanceNoticeDays': advanceNoticeDays,
  });
  return SettingsService.load();
}

Widget buildHarness({
  required SettingsService settings,
  required FakeTaskListNotifier fakeNotifier,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(() => SettingsNotifier()..preload(settings)),
      taskListProvider.overrideWith(() => fakeNotifier),
    ],
    child: const MaterialApp(home: AddTaskScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('"Browse presets" button is visible on Add Task screen',
      (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    expect(find.text('Browse presets'), findsOneWidget);
  });

  testWidgets('Tapping "Browse presets" opens the bottom sheet',
      (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.tap(find.text('Browse presets'));
    await tester.pumpAndSettle();

    // Bottom sheet should be visible — look for a preset name
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('Bottom sheet shows preset names', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.tap(find.text('Browse presets'));
    await tester.pumpAndSettle();

    // At least one preset name from the library should be visible
    final firstPreset = PresetLibrary.presets.first;
    expect(find.text(firstPreset.name), findsWidgets);
  });

  testWidgets('Tapping a preset closes sheet and fills name field',
      (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.tap(find.text('Browse presets'));
    await tester.pumpAndSettle();

    // Tap the first preset in the list
    final firstPreset = PresetLibrary.presets.first;
    await tester.tap(find.text(firstPreset.name).first);
    await tester.pumpAndSettle();

    // Sheet should be dismissed
    expect(find.byType(BottomSheet), findsNothing);

    // Name field should be pre-filled
    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('task_name_field')),
    );
    expect(nameField.controller?.text, firstPreset.name);
  });
}
