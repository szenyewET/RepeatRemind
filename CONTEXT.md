# CONTEXT.md — RepeatRemind

Domain vocabulary. Use these terms consistently across code, comments, and documentation.

---

## Interval
Value object grouping an `IntervalType` (days / weeks / months) and a numeric `value`. Stored on `Task`. `km` type added in Phase 2; the exhaustive switch in `IntervalCalculator` will force all call sites to handle it.

## IntervalCalculator
Pure-computation module. Two responsibilities: calculate `nextDueDate` from a completion date + `Interval`; calculate `notifyAt` from `nextDueDate` + `advanceNoticeDays`. No I/O, no state. Single test surface for all date arithmetic including month-end edge cases and leap years.

## commitCompletion
The atomic mutation for marking a Task done. Accepts a `Task` and a user-confirmed `nextDueDate` (already previewed on-screen). Atomically: appends to `completionHistory`, cancels old notification, schedules new notification at `notifyAt`, persists to DB. Lives on `TaskRepository`.

## previewNextDueDate
Pure computation on `TaskRepository` — returns the suggested `nextDueDate` for display in the Mark as Done dialog. The screen calls this first, shows the result to the user (who may adjust it), then passes the confirmed value to `commitCompletion`. Both methods use the same `IntervalCalculator` instance — the date shown to the user is guaranteed to match what gets scheduled. Screens must call this, not `IntervalCalculator` directly.

## notifyAt
The `DateTime` when a notification fires. Calculated as `nextDueDate − advanceNoticeDays`, clamped to `now + 1 hour` minimum to prevent immediate-fire edge cases when advance notice exceeds the interval.

## TaskRepository
Single coordinator for all task mutations. Composes `DatabaseService` + `NotificationService` + `IntervalCalculator`. The only module that touches both DB and notifications. `rescheduleAll()` lives here — not on `NotificationService` — because it requires reading all tasks from the DB.

## advanceNoticeDays
How many days before `nextDueDate` to fire the notification. Stored on `Task`. Default: 1. Used by `IntervalCalculator.notifyAt`.

## Task
Core domain object. Immutable (all fields final); mutations produce new instances via `copyWith`. Never mutated directly — all changes go through `TaskRepository`. `task.completing(confirmedNextDueDate)` is the domain method that produces the post-completion Task (updated `nextDueDate` + appended `completionHistory`); used by both `TaskRepository.commitCompletion` and `TaskListNotifier` for optimistic state.

## TaskSections
Value object produced by `TaskSections.from(List<Task> tasks, DateTime now)`. Holds three sorted lists: `overdue` (nextDueDate strictly before today), `dueSoon` (today through 7 days out, inclusive), `upcoming` (beyond 7 days). All sections sorted ascending by `nextDueDate`. Pure computation — no I/O, testable with a fixed `now`. Consumed by HomeScreen via `taskSectionsProvider` (derived Riverpod provider). "Due today" falls in `dueSoon`, not `overdue`. Phase 2 km-based tasks are out of scope for `TaskSections` — defer to Phase 2.

**Root widget rule:** On app resume (`AppLifecycleState.resumed`), call both `ref.invalidate(taskSectionsProvider)` and `taskRepository.rescheduleAll()`. These are co-located in a `WidgetsBindingObserver` on the root widget — one handles section staleness, the other handles notification staleness after device restart or reinstall.
