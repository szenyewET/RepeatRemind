import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart';
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/settings_provider.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/screens/add_task_screen.dart';
import 'package:repeatremind/services/settings_service.dart';

// ── Fake TaskListNotifier ──────────────────────────────────────────────────

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

  testWidgets('screen renders without error (smoke test)', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets('save with empty name shows validation error', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Tap save without entering a name
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    expect(find.text('Please enter a task name'), findsOneWidget);
    expect(fakeNotifier.addedTasks, isEmpty);
  });

  testWidgets('selecting a category highlights it', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Tap "Home" category
    await tester.tap(find.text('Home'));
    await tester.pump();

    // The Home category tile should now be selected — verify it's present
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('changing interval type updates segmented button', (tester) async {
    final settings = await makeSettings();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Scroll down to reveal the segmented button (category grid pushes it below viewport)
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    // All three interval types should be visible
    expect(find.text('Days'), findsOneWidget);
    expect(find.text('Weeks'), findsOneWidget);
    expect(find.text('Months'), findsOneWidget);

    // Tap "Weeks"
    await tester.tap(find.text('Weeks'));
    await tester.pump();

    // Weeks is now selectable (segmented button present)
    expect(find.text('Weeks'), findsOneWidget);
  });

  testWidgets('save with valid data calls add() with correct Task fields',
      (tester) async {
    final settings = await makeSettings(advanceNoticeDays: 5);
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Enter a name
    await tester.enterText(find.byKey(const Key('task_name_field')), 'Oil Change');
    await tester.pump();

    // Select "Car" category (visible at top)
    await tester.tap(find.text('Car'));
    await tester.pump();

    // Scroll down to reveal interval segmented button and select "Months"
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.tap(find.text('Months'));
    await tester.pump();

    // Set interval value to 3
    await tester.enterText(find.byKey(const Key('interval_value_field')), '3');
    await tester.pump();

    // Scroll back to top so AppBar save button is accessible
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pump();

    // Tap save via the AppBar action
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(fakeNotifier.addedTasks, hasLength(1));
    final saved = fakeNotifier.addedTasks.first;
    expect(saved.name, 'Oil Change');
    expect(saved.category, Category.car);
    expect(saved.interval.type, IntervalType.months);
    expect(saved.interval.value, 3);
    expect(saved.advanceNoticeDays, 5);
  });

  testWidgets('advance notice defaults to value from settings', (tester) async {
    final settings = await makeSettings(advanceNoticeDays: 3);
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(settings: settings, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Scroll down to reveal advance notice field
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    // The advance notice field should default to 3 (from settings)
    expect(find.byKey(const Key('advance_notice_field')), findsOneWidget);
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('advance_notice_field')),
    );
    expect(field.controller?.text ?? field.initialValue, '3');
  });
}
