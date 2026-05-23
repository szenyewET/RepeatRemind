import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart' as ri;
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/screens/home_screen.dart';

import '../helpers/fake_notifications_plugin.dart';

// ── Fake TaskListNotifier ──────────────────────────────────────────────────

class FakeTaskListNotifier extends AsyncNotifier<List<Task>>
    implements TaskListNotifier {
  final List<Task> _initial;
  FakeTaskListNotifier([this._initial = const []]);

  @override
  Future<List<Task>> build() async => _initial;

  @override
  Future<void> add(Task task) async {
    state = AsyncData([...?state.value, task]);
  }

  @override
  Future<void> commitCompletion(Task task, DateTime confirmedNextDueDate) async {
    state = AsyncData(
      state.value!
          .map((t) => t.id == task.id ? task.completing(confirmedNextDueDate) : t)
          .toList(),
    );
  }

  @override
  Future<void> edit(Task task) async {}

  @override
  Future<void> delete(Task task) async {}
}

// ── Fake NotificationService ───────────────────────────────────────────────

class FakeNotificationService {
  bool requestPermissionCalled = false;
  Future<bool> requestPermission() async {
    requestPermissionCalled = true;
    return true;
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

Task makeTask({
  required String name,
  required DateTime nextDueDate,
}) =>
    Task(
      name: name,
      category: Category.car,
      interval: const ri.Interval(type: ri.IntervalType.months, value: 3),
      nextDueDate: nextDueDate,
    );

Widget buildHarness({List<Task> tasks = const []}) {
  final fakePlugin = FakeNotificationsPlugin();
  final fakeNotifier = FakeTaskListNotifier(tasks);

  return ProviderScope(
    overrides: [
      notificationsPluginProvider.overrideWithValue(fakePlugin),
      taskListProvider.overrideWith(() => fakeNotifier),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Suppress permission dialog in tests
    SharedPreferences.setMockInitialValues({
      'notificationPermissionAsked': true,
    });
  });

  testWidgets('empty state shows "No tasks yet" when task list is empty',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();

    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('summary chip shows "All clear" when no due-soon tasks',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();

    expect(find.text('All clear'), findsOneWidget);
  });

  testWidgets('summary chip shows "X due this week" when due-soon tasks exist',
      (tester) async {
    final now = DateTime.now();
    final tasks = [
      makeTask(name: 'Task A', nextDueDate: now.add(const Duration(days: 2))),
      makeTask(name: 'Task B', nextDueDate: now.add(const Duration(days: 4))),
    ];

    await tester.pumpWidget(buildHarness(tasks: tasks));
    await tester.pump();

    expect(find.text('2 due this week'), findsOneWidget);
  });

  testWidgets('Overdue section header visible when there are overdue tasks',
      (tester) async {
    final now = DateTime.now();
    final tasks = [
      makeTask(
          name: 'Old Task',
          nextDueDate: now.subtract(const Duration(days: 3))),
    ];

    await tester.pumpWidget(buildHarness(tasks: tasks));
    await tester.pump();

    // Section header + task card countdown both show "Overdue" — at least one present.
    expect(find.text('Overdue'), findsAtLeastNWidgets(1));
  });

  testWidgets('Due Soon section header visible when there are due-soon tasks',
      (tester) async {
    final now = DateTime.now();
    final tasks = [
      makeTask(name: 'Soon Task', nextDueDate: now.add(const Duration(days: 3))),
    ];

    await tester.pumpWidget(buildHarness(tasks: tasks));
    await tester.pump();

    expect(find.text('Due Soon'), findsOneWidget);
  });

  testWidgets('FAB "+" is present on screen', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
