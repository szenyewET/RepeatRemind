# RepeatRemind — Build Plan

---

## Recommended Tech Stack

### Cross-Platform (Recommended)
Build once, ship to both Play Store and App Store.

| Layer | Choice | Why |
|---|---|---|
| Framework | **Flutter** (Dart) | Best cross-platform for this type of utility app. Smooth UI, good notification support, single codebase for Android + iOS |
| Local Database | **Hive** | Simpler API than drift, no SQL needed for this data model, fast to learn |
| Notifications | **flutter_local_notifications** | Handles scheduled notifications on both platforms reliably |
| State Management | **Riverpod** | More modern than Provider, better docs, active community |
| Widget (home screen) | **home_widget** package | Supports Android & iOS home screen widgets from Flutter |

### Alternative: React Native
- Also cross-platform, large community
- Slightly more complex for local notifications
- Good if you already know JavaScript/React

### NOT Recommended for v1:
- Native Swift/Kotlin (double the work, double the maintenance)
- Backend/server (unnecessary — everything is local)

---

## Development Phases

---

### Phase 1 — MVP (4–6 weeks)
**Goal:** Minimum viable app to submit to stores.

**Features to build:**
- [ ] Add / Edit / Delete tasks
- [ ] Time-based intervals (days / weeks / months)
- [ ] Push notification scheduling
- [ ] Home screen dashboard (Overdue / Due Soon / Upcoming)
- [ ] Mark as Done → auto-reschedule
- [ ] Basic categories (Car / Home / Pet / Health / Other)
- [ ] Dark mode support
- [ ] Onboarding flow (3 screens)

**Not in MVP:**
- km/mileage-based intervals (Phase 2)
- Widget (Phase 2)
- History log (Phase 2)

**Moved from Phase 2 → Phase 1:**
- Preset task library (15+ built-in tasks) — blank text field on first launch kills activation for new homeowners who don't know what to track

**Store submission checklist:**
- [ ] Privacy policy hosted at live URL (GitHub Pages — must exist before submission)
- [ ] App icon (1024x1024 PNG)
- [ ] Screenshots: 6.7" iPhone (1290×2796px) + 5.5" iPhone (1242×2208px) — iPhone only, no iPad
- [ ] Restrict to iPhone-only in Xcode (Requires full screen + uncheck iPad deployment target)
- [ ] Short & full description
- [ ] IARC content rating questionnaire (both stores — answer: Everyone / 4+)
- [ ] Android keystore created + `key.properties` configured (do this Week 1 — losing keystore = cannot update app ever; back up to at minimum iCloud/Drive)
- [ ] Google Play Data Safety form completed (all answers: no data collected, no data shared)
- [ ] iOS export compliance (no custom encryption — select standard exemption)
- [ ] Test on real Android + iOS device

---

### Phase 2 — Full Launch (3–4 weeks after MVP)
**Goal:** Differentiated, feature-complete v1.1

**Features to build:**
- [ ] km / miles distance-based intervals
- [ ] Expand preset library to 30+ built-in tasks (Phase 1 ships 15+)
- [ ] Completion history log (per task)
- [ ] Home screen widget (small + medium)
- [ ] Snooze option on tasks
- [ ] Notes field per task
- [ ] Smart name suggestions (type "oil" → suggest "Oil Change")

---

### Phase 3 — Growth (ongoing)
**Goal:** Improve retention + ratings

**Features to build:**
- [ ] Export tasks as CSV/JSON (backup)
- [ ] Import from CSV (restore / migrate)
- [ ] Overdue summary notification (weekly digest)
- [ ] Share task card as image (social)
- [ ] iCloud / Google Drive backup (optional)
- [ ] Siri Shortcuts / Google Assistant integration

---

## Package Name

`com.edgecom.repeatremind` — set at project creation, never change after first submission.

```bash
flutter create --org com.edgecom repeatremind
```

## Folder Structure (Flutter)

```
repeatremind/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── task.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── add_task_screen.dart
│   │   ├── task_detail_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/
│   │   ├── task_card.dart
│   │   └── category_icon.dart
│   ├── services/
│   │   ├── notification_service.dart
│   │   └── database_service.dart
│   └── providers/
│       └── task_provider.dart
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## Task Data Model

```dart
class Task {
  String id;
  String name;
  String category;        // car, home, pet, health, garden, other
  String intervalType;    // 'days' | 'weeks' | 'months' | 'km'
  int intervalValue;      // e.g. 3 (months), 5000 (km)
  DateTime nextDueDate;
  int? advanceNoticeDays; // notify X days before
  String? notes;
  List<DateTime> completionHistory;
  DateTime createdAt;
}
```

---

## Notification Strategy

- Schedule notifications using **flutter_local_notifications** at task creation time
- When a task is marked done: cancel old notification, schedule new one
- Handle Android 13+ notification permission request on app first launch
- Handle iOS permission request on onboarding screen

**Android manifest permissions required:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

**Edge cases to handle:**
- App uninstalled and reinstalled → reschedule all notifications on app open
- Device restart → reschedule all notifications (use boot receiver on Android)
- Notification permission denied → show in-app banner on home screen

---

## Store Submission Notes

### Google Play Store
- Developer account: $25 one-time fee
- Review time: 1–3 days (new apps), often same day for updates
- Requires: Privacy policy, data safety section, IARC content rating
- Target audience: **18+** (homeowners/car owners — declare "not targeting children")
- Permissions to declare: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`
- **Build command: `flutter build appbundle --release`** (NOT `flutter build apk` — AAB required since Aug 2021)
- Target API: Android 14 (API 34) — required for new apps as of Aug 2024

### Apple App Store
- Developer account: $99/year
- Minimum iOS: **16** (set in Xcode deployment target — covers 95%+ of active iPhones, cleaner notification APIs)
- Review time: 24–48 hours typically
- Requires: Privacy policy, App Privacy labels, IARC content rating (4+), export compliance (no custom encryption — standard exemption)
- Target audience: **18+** — age rating 4+ (content is clean) but audience declared as adults
- **Info.plist entries required (add in Week 1, not at submission):**
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>RepeatRemind uses notifications to remind you when maintenance tasks are due.</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```
- Screenshots: 6.7" iPhone required (iPhone 15 Pro Max size) + 5.5" iPhone

### Privacy Policy Requirements
Both stores require a live, accessible URL before submission (they verify it resolves — 404 = rejection).

Host on GitHub Pages: `https://[yourusername].github.io/repeatremind/privacy`

Content (data stored locally, nothing collected):
> *RepeatRemind stores all data locally on your device only. No personal data is collected, transmitted, or shared with third parties. No account or registration is required.*

**Set up in Week 5, not at submission time.**

---

## Estimated Timeline

| Phase | Duration | Milestone |
|---|---|---|
| Setup + Architecture | Week 1 | Project scaffold, DB, Info.plist notification keys, Android manifest permissions, notifications wired up |
| Core Screens | Week 2–3 | Add/edit/delete tasks, home screen |
| Notifications + Logic | Week 4 | Scheduling, auto-reschedule on completion |
| Polish + Testing | Week 5 | Dark mode, onboarding, real device testing |
| **Phase 1 Submission** | **Week 6** | **Submit to both stores** |
| Phase 2 Features | Week 7–9 | km support, presets, widget, history |
| **Phase 2 Update** | **Week 10** | **v1.1 update submitted** |

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Notification doesn't fire reliably on Android | Low | Notify 3–7 days early (not exact-time) — Doze mode delay irrelevant at this granularity |
| iOS notification permission rejected by user | Medium | Show value prop before requesting; handle gracefully |
| App Store rejection | Low | Follow guidelines strictly; no user data collected |
| Competitor copies the idea | Medium | Move fast; build reviews and ASO early |

---

*Document: Build Plan | RepeatRemind | v1.0 — May 2026*
