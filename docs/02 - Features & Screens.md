# RepeatRemind — Features & Screens

---

## App Flow Overview

```
Splash / Onboarding (first launch only)
        ↓
Home Screen — Task Dashboard
   ├── Due Soon (next 7 days)
   ├── Overdue (past due date)
   └── All Tasks (grouped by category)
        ↓
Add / Edit Task Screen
        ↓
Task Detail Screen
   ├── Mark as Done → auto-reschedule
   ├── Snooze
   └── Edit
        ↓
Settings Screen
   ├── Notification preferences
   ├── Units (km / miles)
   └── Theme (light / dark)
```

---

## Screen-by-Screen Breakdown

---

### 1. Home Screen — Task Dashboard

**Purpose:** Give the user an instant status of all their maintenance tasks.

**Layout:**
- Top banner: "X tasks due this week" with a progress ring
- Section 1: 🔴 **Overdue** — tasks past their due date
- Section 2: 🟡 **Due Soon** — tasks due in the next 7 days
- Section 3: 🟢 **Upcoming** — everything else, sorted by next due date

**Each task card shows:**
- Task name + icon (by category)
- Days/km until due (e.g. "Due in 3 days" or "Due in 800 km")
- Category color tag (Car 🚗 / Home 🏠 / Pet 🐾 / Health 🏥 / Other ⚙️)
- Quick "Done" swipe action (right swipe → mark complete)

**Bottom nav bar:**
- Home | Add (+) | Settings

---

### 2. Add / Edit Task Screen

**Purpose:** Let users create a new task in under 30 seconds.

**Fields:**
- **Task Name** (text input) — e.g. "Oil Change"
- **Category** (icon selector) — Car / Home / Pet / Health / Garden / Other
- **Interval Type** (toggle) — Time-based OR Distance-based
  - If Time: days / weeks / months picker
  - If Distance: km or miles input
- **First Due Date** — date picker (defaults to today + interval)
- **Reminder** — how early to notify (e.g. 1 day before / 3 days before)
- **Notes** (optional) — e.g. "Use 5W-30 oil"

**Smart suggestions:** When user types a task name, show preset suggestions:
- "Oil Change" → auto-fill: Car, Every 5,000 km
- "Descale Coffee Machine" → auto-fill: Home, Every 3 months
- "Flea Treatment" → auto-fill: Pet, Every 4 weeks

---

### 3. Task Detail Screen

**Purpose:** View full task info and take action.

**Shows:**
- Task name, category, next due date
- Interval (e.g. "Repeats every 3 months")
- Countdown: "Due in 12 days"
- History log: last 5 completions with dates
- Notes field

**Action buttons:**
- ✅ **Mark as Done** — logs completion, auto-calculates next due date
- ⏭️ **Snooze** — push due date by X days (user picks)
- ✏️ **Edit** — opens Edit Task screen
- 🗑️ **Delete** — with confirmation

---

### 4. Mark as Done Flow

When user taps "Mark as Done":
1. ✅ Satisfying checkmark animation + haptic feedback
2. Prompt: "Next due: [auto-calculated date]. Looks right?" with Yes / Adjust options
3. Task moves to Upcoming section
4. History log updated

**For distance-based tasks:**
1. Ask: "Current odometer reading?" (optional — can skip)
2. Calculates next due km based on entered reading

---

### 5. Home Screen Widget

**Small (2x2):** Shows count of overdue + due-this-week tasks
**Medium (4x2):** Shows top 3 upcoming tasks with days remaining
**Large (4x4):** Full list of due soon and overdue tasks

---

### 6. Onboarding (First Launch Only)

3 swipeable cards:
1. "Maintenance tasks that repeat on weird schedules? We got you."
2. "Set it once. We remind you. You mark it done. Repeat."
3. "Works offline. No account needed. Let's add your first task." → CTA button

**Then:** Jump straight to Add Task screen with 3 popular preset suggestions to accept in one tap.

---

### 7. Settings Screen

- **Notification time** — what time of day to receive reminders
- **Advance notice** — default days-before for new tasks
- **Distance unit** — km / miles toggle
- **Theme** — Light / Dark / System
- **Export data** — export all tasks as CSV or JSON (for backup)
- **About / Rate the app**

---

## Notification Design

**Push notification copy examples:**

> 🚗 **Oil Change is due in 3 days**
> Last done: Feb 12 · Next: May 23 · Tap to log it done

> 🏠 **Water Filter Replacement overdue by 2 days**
> Tap to mark complete or snooze

> 🐾 **Flea Treatment due today**
> Tap to log it done

---

## Preset Task Library (Built-in)

When adding a task, users can pick from a preset library instead of typing from scratch:

**🚗 Car**
- Oil Change (every 5,000 km)
- Tyre Rotation (every 10,000 km)
- Air Filter Replacement (every 20,000 km)
- Car Wash (every 2 weeks)
- Registration Renewal (every 12 months)

**🏠 Home**
- Descale Coffee Machine (every 3 months)
- Replace Water Filter (every 6 months)
- Clean Air Conditioner Filter (every 3 months)
- Vacuum Under Furniture (every 1 month)
- Test Smoke Detector (every 6 months)
- Check Fire Extinguisher (every 12 months)

**🐾 Pet**
- Flea & Tick Treatment (every 4 weeks)
- Heartworm Medication (every 30 days)
- Vet Check-up (every 12 months)
- Grooming (every 6 weeks)

**🏥 Health**
- Dental Check-up (every 6 months)
- Eye Test (every 12 months)
- Blood Test (every 12 months)

**🌿 Garden**
- Fertilize Plants (every 4 weeks)
- Water Indoor Plants (every 3 days)
- Mow Lawn (every 2 weeks)

---

*Document: Features & Screens | RepeatRemind | v1.0 — May 2026*
