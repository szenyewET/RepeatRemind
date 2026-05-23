import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart' as ri;
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/settings_provider.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/screens/add_task_screen.dart';
import 'package:repeatremind/services/settings_service.dart';

import '../helpers/fake_notifications_plugin.dart';

// ── Fake TaskListNotifier ──────────────────────────────────────────────────

class FakeTaskListNotifier extends AsyncNotifier<List<Task>>
    implements TaskListNotifier {
  final List<Task> addedTasks = [];
  final List<Task> editedTasks = [];

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
  Future<void> edit(Task task) async {
    editedTasks.add(task);
    final current = state.value ?? [];
    state = AsyncData(current.map((t) => t.id == task.id ? task : t).toList());
  }

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

Task makeExistingTask() => Task(
      name: 'Brake Check',
      category: Category.car,
      interval: const ri.Interval(type: ri.IntervalType.months, value: 6),
      nextDueDate: DateTime(2026, 9, 1),
      advanceNoticeDays: 3,
    );

Widget buildHarness({
  required SettingsService settings,
  required FakeTaskListNotifier fakeNotifier,
  Task? initialTask,
}) {
  final fakePlugin = FakeNotificationsPlugin();
  return ProviderScope(
    overrides: [
      notificationsPluginProvider.overrideWithValue(fakePlugin),
      settingsProvider.overrideWith(() => SettingsNotifier()..preload(settings)),
      taskListProvider.overrideWith(() => fakeNotifier),
    ],
    child: MaterialApp(home: AddTaskScreen(initialTask: initialTask)),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('edit screen shows "Edit Task" title when initialTask is provided',
      (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    final task = makeExistingTask();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier, initialTask: task));
    await tester.pump();

    expect(find.text('Edit Task'), findsOneWidget);
  });

  testWidgets('edit screen pre-fills task name', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    final task = makeExistingTask();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier, initialTask: task));
    await tester.pump();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('task_name_field')),
    );
    expect(nameField.controller?.text, 'Brake Check');
  });

  testWidgets('edit screen pre-fills category selection', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    final task = makeExistingTask();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier, initialTask: task));
    await tester.pump();

    // Car category should be visible; the test verifies it renders
    expect(find.text('Car'), findsOneWidget);
  });

  testWidgets('save on edit calls TaskListNotifier.edit() not .add()', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    final task = makeExistingTask();
    await tester.pumpWidget(
        buildHarness(settings: settings, fakeNotifier: fakeNotifier, initialTask: task));
    await tester.pump();

    // Change the name
    await tester.enterText(find.byKey(const Key('task_name_field')), 'Updated Brakes');
    await tester.pump();

    // Tap save via the AppBar action
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(fakeNotifier.editedTasks, hasLength(1));
    expect(fakeNotifier.addedTasks, isEmpty);
    expect(fakeNotifier.editedTasks.first.name, 'Updated Brakes');
    // Preserved fields from original task
    expect(fakeNotifier.editedTasks.first.id, task.id);
    expect(fakeNotifier.editedTasks.first.createdAt, task.createdAt);
  });
}
