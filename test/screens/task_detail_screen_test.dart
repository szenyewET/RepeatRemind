import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeatremind/models/category.dart';
import 'package:repeatremind/models/interval.dart' as ri;
import 'package:repeatremind/models/task.dart';
import 'package:repeatremind/providers/task_provider.dart';
import 'package:repeatremind/screens/task_detail_screen.dart';

import '../helpers/fake_notifications_plugin.dart';

// ── Fake TaskListNotifier ──────────────────────────────────────────────────

class FakeTaskListNotifier extends AsyncNotifier<List<Task>>
    implements TaskListNotifier {
  final List<Task> deletedTasks = [];

  @override
  Future<List<Task>> build() async => [];

  @override
  Future<void> add(Task task) async {}

  @override
  Future<void> commitCompletion(Task task, DateTime confirmedNextDueDate) async {}

  @override
  Future<void> edit(Task task) async {}

  @override
  Future<void> delete(Task task) async {
    deletedTasks.add(task);
    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != task.id).toList());
  }
}

// ── Test helpers ──────────────────────────────────────────────────────────

Task makeTask({String? notes}) => Task(
      name: 'Oil Change',
      category: Category.car,
      interval: const ri.Interval(type: ri.IntervalType.months, value: 3),
      nextDueDate: DateTime(2026, 6, 15),
      advanceNoticeDays: 7,
      notes: notes,
    );

Widget buildHarness({required Task task, required FakeTaskListNotifier fakeNotifier}) {
  final fakePlugin = FakeNotificationsPlugin();
  return ProviderScope(
    overrides: [
      notificationsPluginProvider.overrideWithValue(fakePlugin),
      taskListProvider.overrideWith(() => fakeNotifier),
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

  testWidgets('renders task name in AppBar', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    expect(find.text('Oil Change'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows category display name', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    expect(find.text('Car'), findsOneWidget);
  });

  testWidgets('shows interval string "Every 3 months"', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    expect(find.text('Every 3 months'), findsOneWidget);
  });

  testWidgets('shows formatted next due date', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    expect(find.text('15 Jun 2026'), findsOneWidget);
  });

  testWidgets('shows notes when present', (tester) async {
    final task = makeTask(notes: 'Use synthetic oil');
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    expect(find.text('Use synthetic oil'), findsOneWidget);
  });

  testWidgets('hides notes row when notes is null', (tester) async {
    final task = makeTask(notes: null);
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Notes row should not be rendered
    expect(find.byKey(const Key('notes_row')), findsNothing);
  });

  testWidgets('delete icon tap shows confirmation dialog', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete task?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);
  });

  testWidgets('confirming delete calls TaskListNotifier.delete()', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fakeNotifier.deletedTasks, hasLength(1));
    expect(fakeNotifier.deletedTasks.first.id, task.id);
  });

  testWidgets('"Mark as Done" button is present', (tester) async {
    final task = makeTask();
    final fakeNotifier = FakeTaskListNotifier();
    await tester.pumpWidget(buildHarness(task: task, fakeNotifier: fakeNotifier));
    await tester.pump();

    // Scroll down to ensure button is visible
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    expect(find.text('Mark as Done'), findsOneWidget);
  });
}
