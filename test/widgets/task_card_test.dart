import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart' as ri;
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/widgets/task_card.dart';

import '../helpers/fake_notifications_plugin.dart';

// ── Fake TaskListNotifier ──────────────────────────────────────────────────

class FakeTaskListNotifier extends AsyncNotifier<List<Task>>
    implements TaskListNotifier {
  Task? completedTask;
  DateTime? completedDate;

  @override
  Future<List<Task>> build() async => [];

  @override
  Future<void> add(Task task) async {}

  @override
  Future<void> commitCompletion(Task task, DateTime confirmedNextDueDate) async {
    completedTask = task;
    completedDate = confirmedNextDueDate;
  }

  @override
  Future<void> edit(Task task) async {}

  @override
  Future<void> delete(Task task) async {}
}

// ── Helpers ────────────────────────────────────────────────────────────────

Task makeTask({required DateTime nextDueDate, String name = 'Oil Change'}) =>
    Task(
      name: name,
      category: Category.car,
      interval: const ri.Interval(type: ri.IntervalType.months, value: 3),
      nextDueDate: nextDueDate,
    );

Widget buildCardHarness(Task task, FakeTaskListNotifier fakeNotifier) {
  final fakePlugin = FakeNotificationsPlugin();

  return ProviderScope(
    overrides: [
      notificationsPluginProvider.overrideWithValue(fakePlugin),
      taskListProvider.overrideWith(() => fakeNotifier),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TaskCard(task: task),
      ),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('task card renders task name', (tester) async {
    final now = DateTime.now();
    final task = makeTask(nextDueDate: now.add(const Duration(days: 5)));
    final fakeNotifier = FakeTaskListNotifier();

    await tester.pumpWidget(buildCardHarness(task, fakeNotifier));
    await tester.pump();

    expect(find.text('Oil Change'), findsOneWidget);
  });

  testWidgets('countdown shows "Overdue" for past-due task', (tester) async {
    final now = DateTime.now();
    final task =
        makeTask(nextDueDate: now.subtract(const Duration(days: 2)));
    final fakeNotifier = FakeTaskListNotifier();

    await tester.pumpWidget(buildCardHarness(task, fakeNotifier));
    await tester.pump();

    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('countdown shows "Today" for today\'s task', (tester) async {
    final now = DateTime.now();
    // Same day — use noon to avoid any midnight edge case
    final today = DateTime(now.year, now.month, now.day, 12);
    final task = makeTask(nextDueDate: today);
    final fakeNotifier = FakeTaskListNotifier();

    await tester.pumpWidget(buildCardHarness(task, fakeNotifier));
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('countdown shows "X days" for future task', (tester) async {
    final now = DateTime.now();
    final task = makeTask(nextDueDate: now.add(const Duration(days: 10)));
    final fakeNotifier = FakeTaskListNotifier();

    await tester.pumpWidget(buildCardHarness(task, fakeNotifier));
    await tester.pump();

    expect(find.text('10 days'), findsOneWidget);
  });

  testWidgets('right-swipe calls commitCompletion', (tester) async {
    final now = DateTime.now();
    final task = makeTask(nextDueDate: now.add(const Duration(days: 30)));
    final fakeNotifier = FakeTaskListNotifier();

    await tester.pumpWidget(buildCardHarness(task, fakeNotifier));
    await tester.pump();

    // Perform a right-swipe on the Dismissible
    await tester.drag(find.byType(Dismissible), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(fakeNotifier.completedTask, isNotNull);
    expect(fakeNotifier.completedTask!.id, task.id);
  });
}
