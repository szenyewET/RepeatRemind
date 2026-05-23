import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart' as ri;
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/screens/task_detail_screen.dart';
import 'package:repeatremind/services/task_repository.dart';

import '../helpers/fake_notifications_plugin.dart';

// ── Fake TaskListNotifier ──────────────────────────────────────────────────

class FakeTaskListNotifier extends AsyncNotifier<List<Task>>
    implements TaskListNotifier {
  final List<({Task task, DateTime confirmedDate})> completionCalls = [];

  @override
  Future<List<Task>> build() async => [];

  @override
  Future<void> add(Task task) async {}

  @override
  Future<void> commitCompletion(Task task, DateTime confirmedNextDueDate) async {
    completionCalls.add((task: task, confirmedDate: confirmedNextDueDate));
    final current = state.value ?? [];
    state = AsyncData(
      current
          .map((t) => t.id == task.id ? task.completing(confirmedNextDueDate) : t)
          .toList(),
    );
  }

  @override
  Future<void> edit(Task task) async {}

  @override
  Future<void> delete(Task task) async {}
}

// ── Fake TaskRepository ───────────────────────────────────────────────────

class FakeTaskRepository implements TaskRepository {
  final DateTime previewDate;

  FakeTaskRepository({required this.previewDate});

  @override
  DateTime previewNextDueDate(Task task, DateTime completionDate) => previewDate;

  @override
  Future<Task> commitCompletion(Task task, DateTime confirmedNextDueDate) async {
    return task.completing(confirmedNextDueDate);
  }

  @override
  List<Task> getAll() => [];

  @override
  Future<Task> add(Task task) async => task;

  @override
  Future<Task> update(Task task) async => task;

  @override
  Future<void> delete(Task task) async {}

  @override
  Future<void> rescheduleAll() async {}
}

// ── Test helpers ──────────────────────────────────────────────────────────

/// A fixed preview date used in all tests so assertions are deterministic.
final _previewDate = DateTime(2026, 9, 15);

Task makeTask() => Task(
      name: 'Oil Change',
      category: Category.car,
      interval: const ri.Interval(type: ri.IntervalType.months, value: 3),
      nextDueDate: DateTime(2026, 6, 15),
      advanceNoticeDays: 7,
    );

Widget buildHarness({
  required Task task,
  required FakeTaskListNotifier fakeNotifier,
  DateTime? previewDate,
}) {
  final fakePlugin = FakeNotificationsPlugin();
  final fakeRepo = FakeTaskRepository(previewDate: previewDate ?? _previewDate);

  return ProviderScope(
    overrides: [
      notificationsPluginProvider.overrideWithValue(fakePlugin),
      taskListProvider.overrideWith(() => fakeNotifier),
      taskRepositoryProvider.overrideWithValue(fakeRepo),
    ],
    child: MaterialApp(home: TaskDetailScreen(task: task)),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('1. "Mark as Done" button is present on TaskDetailScreen',
      (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Scroll to button if needed
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    expect(find.text('Mark as Done'), findsOneWidget);
  });

  testWidgets('2. Tapping "Mark as Done" opens the bottom sheet', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    await tester.tap(find.text('Mark as Done'));
    await tester.pumpAndSettle();

    // Bottom sheet title should be visible
    expect(find.text('Mark as Done'), findsAtLeastNWidgets(1));
    // Sheet should contain the task name as subtitle
    expect(find.text('Oil Change'), findsAtLeastNWidgets(1));
  });

  testWidgets('3. Bottom sheet shows the previewed next due date', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    // previewDate = 15 Sep 2026
    await tester.pumpWidget(buildHarness(
      task: task,
      fakeNotifier: fakeNotifier,
      previewDate: DateTime(2026, 9, 15),
    ));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    await tester.tap(find.text('Mark as Done'));
    await tester.pumpAndSettle();

    // The formatted date "15 Sep 2026" should appear in the sheet
    expect(find.text('15 Sep 2026'), findsOneWidget);
  });

  testWidgets('4. Tapping "Cancel" closes the sheet without calling commitCompletion',
      (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    await tester.tap(find.text('Mark as Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Sheet is gone — the Cancel and Confirm buttons from the sheet are no longer visible
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Confirm'), findsNothing);
    // commitCompletion was never called
    expect(fakeNotifier.completionCalls, isEmpty);
  });

  testWidgets('5. Tapping "Confirm" calls commitCompletion on the notifier',
      (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    await tester.tap(find.text('Mark as Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(fakeNotifier.completionCalls, hasLength(1));
    expect(fakeNotifier.completionCalls.first.task.id, task.id);
  });

  testWidgets('6. Confirmed date matches the previewed date (no user adjustment)',
      (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    final preview = DateTime(2026, 9, 15);
    await tester.pumpWidget(buildHarness(
      task: task,
      fakeNotifier: fakeNotifier,
      previewDate: preview,
    ));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    await tester.tap(find.text('Mark as Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(fakeNotifier.completionCalls, hasLength(1));
    final confirmedDate = fakeNotifier.completionCalls.first.confirmedDate;
    // Date should be same day as preview (time component may differ)
    expect(confirmedDate.year, preview.year);
    expect(confirmedDate.month, preview.month);
    expect(confirmedDate.day, preview.day);
  });

  testWidgets(
      '7. Tapping "Confirm" shows a success SnackBar with the confirmed date',
      (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    final preview = DateTime(2026, 9, 15);
    await tester.pumpWidget(buildHarness(
      task: task,
      fakeNotifier: fakeNotifier,
      previewDate: preview,
    ));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    await tester.tap(find.text('Mark as Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // SnackBar should confirm success with the date
    expect(find.textContaining('15 Sep 2026'), findsOneWidget);
  });
}
