# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project

RepeatRemind — Flutter app for recurring maintenance reminders with custom intervals (time-based and km/mileage-based). Offline-first, no account required. Android + iOS.

All planning documents are in the root as markdown files. No Dart code exists yet — this is pre-implementation.

---

## Tech Stack Decisions (locked)

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Database | Hive or SQLite via `drift` |
| Notifications | `flutter_local_notifications` |
| State | Riverpod or Provider |
| Home widget | `home_widget` package |

Do not propose React Native or native Swift/Kotlin — cross-platform was the deliberate choice to maintain one codebase.

---

## Planned Folder Structure

```
lib/
├── main.dart
├── models/
│   └── task.dart
├── screens/
│   ├── home_screen.dart
│   ├── add_task_screen.dart
│   ├── task_detail_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── task_card.dart
│   └── category_icon.dart
├── services/
│   ├── notification_service.dart
│   └── database_service.dart
└── providers/
    └── task_provider.dart
```

---

## Core Data Model

```dart
class Task {
  String id;
  String name;
  String category;        // car | home | pet | health | garden | other
  String intervalType;    // days | weeks | months | km
  int intervalValue;
  DateTime nextDueDate;
  int? advanceNoticeDays;
  String? notes;
  List<DateTime> completionHistory;
  DateTime createdAt;
}
```

---

## Flutter Commands (once project is scaffolded)

```bash
flutter pub get          # install deps
flutter run              # run on connected device/simulator
flutter build apk        # Android release build
flutter build ios        # iOS release build
flutter test             # run all tests
flutter test test/path/to/test.dart  # single test file
flutter analyze          # static analysis
```

---

## Key Architecture Rules

**Mark as Done flow:** log completion → cancel existing notification → calculate `nextDueDate = now + interval` → schedule new notification → update DB.

**Notification lifecycle:** always cancel + reschedule (never just reschedule). On app open, reschedule all tasks — handles reinstall and device restart cases.

**Distance-based tasks (km/miles):** `nextDueDate` is stored as a km threshold, not a DateTime. The home screen computes "X km remaining" from current odometer (user-entered or estimated).

**Home screen sections:** Overdue → Due Soon (≤7 days) → Upcoming. Task cards show category icon + countdown string. Right-swipe = quick Done.

---

## Phase Priorities

**Phase 1 (MVP — submit to stores):** Add/Edit/Delete tasks, time-based intervals only, push notifications, home screen dashboard, Mark as Done with auto-reschedule, basic categories, dark mode, onboarding.

**Phase 2:** km/miles intervals, preset task library (30+ built-ins), completion history log, home screen widget, snooze, notes, smart name suggestions.

**Phase 3:** CSV/JSON export-import, weekly digest notification, iCloud/Drive backup, Siri/Assistant integration.

Do not implement Phase 2+ features during Phase 1 work.

---

## Notification Edge Cases (must handle)

- Android 13+: request `POST_NOTIFICATIONS` permission on first launch
- iOS: request permission on onboarding screen 3 (before CTA)
- Permission denied: show persistent in-app banner on home screen
- Device restart (Android): reschedule all via `RECEIVE_BOOT_COMPLETED` broadcast receiver
- Reinstall: reschedule all on app open

---

## Store Requirements

- Privacy policy URL required (data stored locally only — no collection/transmission)
- Android permissions to declare: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`
- App icon: 1024×1024 PNG
- No backend, no user accounts, no data leaves the device

---

## Key Design Constraints

- Zero-friction: add a task in under 30 seconds
- Calm UI — no anxiety-inducing red badges; gentle nudges
- Fully offline — no network calls in the app logic
- Categories: Car / Home / Pet / Health / Garden / Other (fixed set for MVP)
