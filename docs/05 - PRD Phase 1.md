# RepeatRemind — PRD: Phase 1 MVP

*Synthesized from concept, grilling sessions, and store approval review — May 2026*

---

## Problem Statement

Standard reminder apps (Google Calendar, iOS Reminders, Samsung Reminder) handle fixed dates and simple daily/weekly/monthly recurrence — but not custom intervals. Homeowners, car owners, and pet owners face dozens of maintenance tasks that repeat on irregular schedules: every 3 months, every 6 weeks, every 5,000 km. After each completion, users must manually reschedule. Most forget. The result is missed oil changes, expired flea treatments, and unchecked smoke detectors — not from laziness but from the absence of a tool designed for this pattern.

No single app handles all maintenance categories (car + home + pet + health), auto-reschedules on completion, works fully offline, and requires no account.

---

## Solution

RepeatRemind is an offline-first Flutter app for recurring maintenance reminders. Users add tasks once with a name, category, and interval. On completion, the app automatically calculates and schedules the next due date. Push notifications fire in advance. No account required. No cloud dependency. All data lives on device.

Target user: homeowners aged 18+ who also own a car or pet. Launch angle: home + pet + health categories. km/mileage support is Phase 2.

---

## User Stories

### Onboarding

1. As a new user, I want to see what the app does in 3 swipeable screens, so that I understand the value before committing.
2. As a new user, I want to skip onboarding entirely, so that I can get straight to adding tasks on repeat visits.
3. As a new user, I want to see popular preset tasks I can add in one tap after onboarding, so that I don't face a blank home screen on first launch.
4. As a new user on iOS, I want to be asked for notification permission on the third onboarding screen (before the CTA), so that I understand why it's needed before I grant it.
5. As a new user on Android 13+, I want to be asked for POST_NOTIFICATIONS permission on first app launch, so that notifications work correctly from the start.

### Adding Tasks

6. As a user, I want to add a maintenance task in under 30 seconds, so that the app doesn't slow me down.
7. As a user, I want to select a category (Car / Home / Pet / Health / Garden / Other) with an icon picker, so that I can visually organise my maintenance list.
8. As a user, I want to set a time-based interval in days, weeks, or months, so that the app knows when to remind me again.
9. As a user, I want to set the first due date with a date picker, so that the app starts reminding me at the right time.
10. As a user, I want to set advance notice (how many days before due to notify), so that I have time to prepare before a task is due.
11. As a user, I want to add optional notes to a task, so that I can store relevant details (e.g. "use 5W-30 oil", "vet contact: 03-1234567").
12. As a user, I want to browse a preset task library organised by category, so that I don't have to type common tasks from scratch.
13. As a user, I want preset tasks to auto-fill category and interval, so that I can add them in one or two taps.
14. As a user, I want the preset library to include at least 15 tasks covering Car, Home, Pet, Health, and Garden, so that most common maintenance items are covered out of the box.

### Home Screen Dashboard

15. As a user, I want to see overdue tasks in a clearly marked section at the top, so that I know what I've already missed.
16. As a user, I want to see tasks due in the next 7 days in a "Due Soon" section, so that I can plan ahead.
17. As a user, I want to see all other upcoming tasks sorted by next due date, so that I have a complete picture of what's coming.
18. As a user, I want each task card to show the task name, category icon, and days until due, so that I can scan the list quickly.
19. As a user, I want to swipe right on a task card to mark it done instantly, so that I can act quickly without opening the detail screen.
20. As a user, I want to see a summary count of tasks due this week at the top of the home screen, so that I get a quick status at a glance.
21. As a user, I want to see a persistent in-app banner if notification permission is denied, so that I know reminders won't fire and can fix it.
22. As a user, I want the home screen to show an empty state with a prompt to add my first task, so that I'm not confused by a blank screen.

### Task Detail

23. As a user, I want to view full task details including name, category, interval, next due date, and notes, so that I have all context in one place.
24. As a user, I want to tap "Mark as Done" from the detail screen, so that I can log completion with more control than a swipe.
25. As a user, I want a satisfying checkmark animation and haptic feedback when I mark a task done, so that the interaction feels rewarding.
26. As a user, I want to see the auto-calculated next due date after marking done and confirm or adjust it, so that I have control over edge cases (e.g. I did it earlier than expected).
27. As a user, I want to edit a task's name, category, interval, advance notice, or notes, so that I can correct mistakes or update intervals.
28. As a user, I want to delete a task with a confirmation prompt, so that I don't accidentally lose it.

### Notifications

29. As a user, I want to receive a push notification when a task is due soon (based on my advance notice setting), so that I'm reminded before the due date arrives.
30. As a user, I want the notification to show the task name, category, and days until due, so that I have context without opening the app.
31. As a user, I want notifications to reschedule automatically when I reinstall the app, so that I don't lose reminders after reinstall.
32. As a user on Android, I want notifications to reschedule automatically after a device restart, so that a reboot doesn't silently kill all my reminders.
33. As a user, I want marking a task done to immediately cancel the existing notification and schedule a new one, so that I don't receive stale reminders.

### Settings

34. As a user, I want to switch between light, dark, and system theme, so that the app matches my device preference.
35. As a user, I want to set a default advance notice (days before due) applied to all new tasks, so that I don't have to configure it every time.
36. As a user, I want to set the time of day I receive notifications, so that reminders don't arrive at inconvenient hours.

---

## Implementation Decisions

### Tech Stack (locked)
- **Framework:** Flutter (Dart)
- **Database:** Hive — simpler API than drift, no SQL needed for the Task data model
- **State management:** Riverpod — better async support than Provider, cleaner dependency injection
- **Notifications:** `flutter_local_notifications`
- **Package name:** `com.edgecom.repeatremind` — set at scaffold time via `flutter create --org com.edgecom repeatremind`
- **Minimum iOS:** 16 (covers 95%+ of active iPhones, cleaner notification APIs)
- **Minimum Android:** API 24 (Android 7)

### Modules

**Task (Hive entity)**
Persisted data model. Fields: `id`, `name`, `category`, `intervalType` (days/weeks/months), `intervalValue`, `nextDueDate`, `advanceNoticeDays`, `notes`, `completionHistory`, `createdAt`. Hive adapter generated via `hive_generator`. This is the core domain object — all other modules depend on it.

**DatabaseService**
Hive box wrapper with single responsibility: CRUD operations for Task objects. No business logic. Exposes: `getAll()`, `save(task)`, `delete(id)`.

**NotificationService**
`flutter_local_notifications` wrapper. Responsibilities: request platform permission, schedule a notification for a task, cancel a notification by task ID, reschedule all tasks (called on app open). Notification model: fires `advanceNoticeDays` before `nextDueDate`, not at exact due time — reduces Android Doze risk significantly.

Android manifest permissions required:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

iOS `Info.plist` required (add in Week 1):
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>RepeatRemind uses notifications to remind you when maintenance tasks are due.</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**TaskRepository**
Single point for all task mutations. Composes DatabaseService + NotificationService. All state changes go through here. Mark as Done flow: log completion → cancel existing notification → calculate `nextDueDate = completionDate + interval` → schedule new notification → update DB.

**TaskProvider (Riverpod)**
`AsyncNotifierProvider` exposing the task list. Drives all UI state. Calls TaskRepository for mutations. UI never touches DatabaseService or NotificationService directly.

**PresetLibrary**
Static, in-memory list of preset task definitions. No persistence. Minimum 15 presets at Phase 1 launch across Car, Home, Pet, Health, Garden. Each preset contains: name, category, intervalType, intervalValue. Selected preset populates Add Task form fields.

### Key Architectural Rules
- Notification lifecycle: always **cancel then reschedule** on any task change — never reschedule alone
- On every app open: call `NotificationService.rescheduleAll()` — handles reinstall and device restart
- No task data is ever deleted when a user marks done — completion logged to `completionHistory`
- `nextDueDate` is always calculated from completion date, not from the previous due date (prevents drift compounding)

---

## Testing Decisions

Good tests verify observable behaviour from the outside — not internal implementation details. Tests should not assert which methods were called internally; they should assert what state or output changed.

**DatabaseService** — Unit tests against an in-memory Hive box. Verify: task saved is retrievable, deleted task is gone, updated task reflects changes.

**NotificationService scheduling logic** — Unit tests with a mocked `flutter_local_notifications`. Verify: correct notification time calculated from `nextDueDate - advanceNoticeDays`, cancel called with correct ID before reschedule.

**Interval calculation** — Pure unit tests for `nextDueDate` calculation across all intervalTypes (days/weeks/months). Edge cases: end of month (Feb 28 + 1 month), leap year, interval of 1 day.

**TaskProvider** — Widget tests verifying state transitions: task added appears in list, completed task moves to upcoming section with updated `nextDueDate`, deleted task is removed.

No tests needed for: screens, onboarding flow, preset library (static data), settings (UI preferences only).

---

## Out of Scope

- km/mileage-based intervals (Phase 2)
- Home screen widget (Phase 2)
- Completion history log UI (Phase 2)
- Snooze option (Phase 2)
- Smart name suggestions / search-as-you-type (Phase 2)
- Export / import CSV or JSON (Phase 3)
- iCloud / Google Drive backup (Phase 3)
- Siri Shortcuts / Google Assistant integration (Phase 3)
- iPad support (iPhone-only for MVP — restrict in Xcode)
- Multiple devices / sync (no backend by design)

---

## Further Notes

**Store submission requirements (both stores):**
- Privacy policy at live URL (GitHub Pages) — set up Week 5, must resolve before submission
- Android: submit as `.aab` via `flutter build appbundle --release` (NOT `flutter build apk`)
- Android target API: 34 (Android 14) — required for new apps Aug 2024+
- iOS: iPhone-only, restrict in Xcode (Requires full screen, uncheck iPad deployment)
- Screenshots: 6.7" iPhone (1290×2796px) + 5.5" iPhone (1242×2208px)
- Target audience: 18+ on both stores — declare not targeting children
- Android keystore: create Week 1, back up to at minimum iCloud/Google Drive (losing keystore = cannot update app)
- IARC content rating: Everyone / 4+ (answer questionnaire during submission)
- Google Play Data Safety: all "no" — no data collected, no data shared, no data leaves device

**User acquisition (post-launch):**
Target homeowner communities first: r/HomeImprovement, r/homeowners, Facebook homeowner groups, Nextdoor. Post the problem story first, app second.

---

*Document: PRD Phase 1 | RepeatRemind | v1.0 — May 2026*
