# TaskFlow – Personal Learning & Task Management App

> **Tagline:** *Learn. Complete. Track. Grow.*

TaskFlow is a production-quality, offline-first personal learning roadmap and task management application built with **Flutter**, **Dart**, and **Material 3**. It is specifically designed for students and developers who receive learning roadmaps, assignments, technical tasks, and project plans in plain text or message format.

TaskFlow automatically transforms unstructured syllabus and roadmap messages into organized learning phases, actionable tasks, and mini projects with implementation checklists—completely on-device without any cloud, backend, or AI dependency.

---

## 🌟 Key Application Features

### 1. 📊 Dynamic Dashboard (Home)
- **Overall Circular Progress Indicator:** Real-time animated circular progress ring displaying overall completion percentage, total tasks, completed tasks, and remaining tasks.
- **Streak Tracker & Daily Goals:** Calculates active learning streak, best streak, total learning days, and daily task target progress (e.g., 3 tasks/day).
- **Metric Cards:** Quick-view counters for Total Phases, Total Tasks, Completed Tasks, and Remaining Tasks.
- **Horizontal Phase Carousel:** Visual mastery cards with linear progress bars for each phase. Tap any phase card to jump directly to its full curriculum.
- **Today's Tasks & Upcoming Deadlines:** Dedicated interactive lists with instant checkboxes that immediately persist to the database and update all dashboard metrics.
- **Recently Updated Tasks:** Quick access to recently modified or completed topics.

### 2. ⚡ Message-to-Tasks Converter (*Core Highlight*)
- **Dedicated Import Screen:** Paste any plain-text learning roadmap, syllabus, or curriculum message directly.
- **100% Local Regex-Powered Engine:** No external APIs or AI required. Pure Dart regular expressions and structured syntactic analysis.
- **Intelligent Recognition:**
  - Detects Phase headings (e.g., `Phase 1 — Dart Programming (Weeks 1–2)`, `Phase 2: ...`, `Module 1 - ...`, `Sprint 1`).
  - Detects Week numbers and durations (e.g., `Weeks 1–2`, `Duration: 3 weeks`).
  - Identifies phase subtitles and descriptions (e.g., `Foundation`, `Core UI`).
  - Extracts numbered lists (`1. ...`, `2) ...`, `[3] ...`).
  - Extracts bulleted items (`- ...`, `* ...`, `• ...`, `+ ...`).
  - Automatically identifies **Mini Projects** sections and nested implementation checklist tasks.
  - Infers priority badges (`[High]`, `[Low]`, urgent/important keywords).
  - Preserves original task titles and descriptions.
- **Interactive Pre-Import Preview:**
  - Expand/collapse detected phases.
  - Check or uncheck items before saving.
  - Edit phase titles, durations, and descriptions.
  - Edit task titles and priorities or remove unwanted items.
  - Add missing phases manually.
  - **Preserves Unparsed Text:** Non-empty lines that don't match any pattern are captured in a dedicated review sheet so no information is lost.
- **Sample Roadmap Included:** One-tap "Try Sample" button loads a full 4-phase Flutter roadmap for quick exploration.

### 3. ✅ Task & Topic Management
- **Task Attributes:** Title, description, phase tag, priority badge (Low, Medium, High), status badge (Pending, In Progress, Completed), optional deadline/due date, and personal notes.
- **Instant Reactive Checkboxes:** Checking or unchecking immediately updates the local database, recalculates streaks, and updates dashboard cards with zero latency.
- **Search & Filters:** Real-time search across task titles, descriptions, and notes. Filter by Status (All, Pending, In Progress, Completed), Phase, and Priority.
- **Bulk Actions:** "Mark Visible as Completed", "Unmark Visible", and "Clear Completed".
- **Detailed Bottom Sheet:** View and edit full descriptions, due dates, completion timestamps, and personal notes.

### 4. 📚 Phase Management
- **Phase Cards:** Shows Phase number, Title, Week duration, total tasks, completed tasks, remaining tasks, completion percentage, and linear progress bar.
- **Reorderable:** Drag and drop phases to reorder your learning journey.
- **Phase Detail Screen:** Dedicated view containing all tasks filtered to that specific phase with status filters and quick task creation.

### 5. 📈 Progress Analytics & Charts
- **Interactive Charts with `fl_chart`:**
  - **Daily Completed Tasks Bar Chart:** Actual number of learning topics completed per day over the last 7 days.
  - **Progress Velocity Line Chart:** Cumulative task completion curve showing learning momentum.
- **Time Range Filters:** Today, Last 7 Days, Last 30 Days, All Time.
- **Phase Mastery Breakdown:** Comparative progress bars across every phase.
- **Milestone Metrics:** Current streak, best streak, total active learning days, and completed mini projects.
- **100% Real Local Data:** Never generates fake progress.

### 6. 🚀 Mini Projects Management
- **Project Structure:** Project name, description, related learning phase, project status, implementation checklist, and notes.
- **Interactive Checklist:** Instant subtask checkboxes (e.g., "Create student model", "Add student", "Search students").
- **Automatic Status Sync:** When all checklist items are checked, the project automatically transitions to Completed.

### 7. 📅 Calendar & Daily Tasks
- **Horizontal Date Strip:** Scrollable 28-day date selector with indicators for days with scheduled or completed tasks.
- **Agenda View:** View tasks due or completed on any selected date.
- **Overdue Alert Banner:** Highlights tasks that have passed their deadline with quick review.
- **No Forced Deadlines:** Tasks do not require a deadline, keeping learning flexible.

### 8. 📝 Notes Section
- **Multi-Level Notes:** Attach notes to a specific Task, a Learning Phase, a Mini Project, or keep General learning notes.
- **Filter by Entity:** Filter notes by General, Phase, Task, or Project.
- **Auto-Persisted:** Saved automatically to local storage with update timestamps.

### 9. ⚙️ Settings & Data Management
- **Appearance:** One-tap Dark Mode and Light Mode toggle.
  - Dark Theme: High-contrast developer palette (`#0B1020` background, `#151C2E` surface, `#7C5CFC` primary accent, `#22C7A9` teal accent, `#F5F7FF` text).
  - Light Theme: Clean modern developer productivity palette (`#F8FAFC` background, `#FFFFFF` cards, `#7C5CFC` accents).
- **Daily Learning Target:** Configurable goal (1, 2, 3, 5, 8, 10 tasks/day).
- **Local Study Reminders:** Configurable daily notification reminder time.
- **JSON Backup Export:** Export entire database into formatted JSON text.
- **JSON Backup Restore:** Restore database from previously exported JSON backup.
- **Progress Report Export:** Generate a Markdown summary report of your entire learning journey to share or archive.
- **Safety Confirmation:** Two-step confirmation dialogs for destructive actions (Clear completed, Reset all data).

---

## 🛠️ Architecture & Technology Stack

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Dark & Light brand color palettes
│   │   └── app_strings.dart        # Strings, app constants & sample roadmaps
│   ├── theme/
│   │   └── app_theme.dart          # Material 3 ThemeData (Dark & Light)
│   └── utils/
│       ├── date_formatter.dart     # Date formatting & relative due date helpers
│       └── streak_calculator.dart  # Consecutive learning day calculations
├── data/
│   ├── models/
│   │   ├── phase_model.dart        # Phase entity with JSON serialization
│   │   ├── task_model.dart         # Task entity with priority & status enums
│   │   ├── project_model.dart      # Mini project entity with checklist
│   │   ├── project_checklist_item_model.dart
│   │   ├── note_model.dart         # Learning note entity
│   │   └── parsed_import_result.dart # Import preview data structures
│   ├── repositories/
│   │   └── database_service.dart   # Hive local persistence & schema migrations
│   └── services/
│       ├── message_parser_service.dart # Local regex message converter engine
│       ├── backup_service.dart     # JSON export/restore & markdown report generator
│       └── notification_service.dart # Local notification settings
├── providers/
│   ├── app_state_provider.dart     # Primary application state, statistics & actions
│   └── theme_provider.dart         # ThemeMode (Dark/Light) management
├── ui/
│   ├── screens/
│   │   ├── main_scaffold.dart      # 5-destination bottom navigation bar
│   │   ├── home/                   # Dashboard with circular progress & streaks
│   │   ├── tasks/                  # Task lists, search, filters, details & edit
│   │   ├── import/                 # Message-to-tasks converter & preview
│   │   ├── phases/                 # Phase cards, reordering & phase details
│   │   ├── progress/               # fl_chart analytics & phase progress
│   │   ├── projects/               # Mini projects & implementation checklists
│   │   ├── calendar/               # Daily task calendar & overdue inspector
│   │   ├── notes/                  # Multi-entity learning notes
│   │   └── settings/               # Themes, goals, backup & restore
│   └── widgets/
│       ├── task_tile.dart          # Reusable task card with interactive checkbox
│       ├── priority_badge.dart     # Low / Medium / High priority chips
│       ├── status_badge.dart       # Pending / In Progress / Completed chips
│       ├── empty_state.dart        # Clean empty illustrations with actions
│       └── confirm_dialog.dart     # Safe confirmation modal
└── main.dart                       # App entry point & dependency injection
```

### Technology Highlights
- **Flutter SDK:** 3.24+ (Dart 3.5+)
- **State Management:** `provider` (version 6.1.5+)
- **Local Persistence:** `hive` & `hive_flutter` (ultra-fast, pure Dart, cross-platform local NoSQL)
- **Settings Store:** `shared_preferences`
- **Charts & Visualizations:** `fl_chart` (custom bar charts, line curves, and circular rings)
- **Formatting:** `intl`
- **Unique Identifiers:** `uuid`

---

## 🧪 Testing Suite & Quality Assurance

TaskFlow includes an automated test suite covering unit tests, regex parser scenarios, streak algorithms, database CRUD operations, and widget smoke tests.

### Running the Tests
To run all 23 tests:
```bash
flutter test
```

### Running Static Analysis
TaskFlow complies strictly with Flutter and Dart analysis guidelines:
```bash
flutter analyze
```
*(Result: 0 errors, 0 warnings, 0 issues)*

### Verified Scenarios in Test Suite
1. **6-Phase Roadmap Extraction:** Automatically parses 6 distinct phases, week durations, and topic lists from unstructured plain text.
2. **Numbered & Bulleted Task Parsing:** Correctly parses `1.`, `2)`, `[3]`, `-`, `*`, `•`, and `+` items.
3. **Mini Projects Extraction:** Detects project sections and groups nested implementation checklist tasks.
4. **Unparsed Text Preservation:** Unrecognized lines are saved for manual review and never silently discarded.
5. **Streak Calculations:** Verified active streak, broken streak, best streak, and total learning days.
6. **Database Persistence & Migrations:** Verified Phase, Task, Project, and Note CRUD operations in local storage.
7. **JSON Backup & Restore:** Complete export and restore roundtrip verifying zero data loss.
8. **Interactive UI Smoke Tests:** Tab switching across all 5 destinations and live progress recalculation when checkboxes are toggled.

---

## 🚀 Building & Running the Application

### 1. Run in Development Mode
```bash
# Get dependencies
flutter pub get

# Run on Chrome/Web
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

### 2. Build for Web
```bash
flutter build web --release
```
The compiled, tree-shaken static assets are generated in `build/web/`.

### 3. Build Release APK for Android
When Android SDK is configured on the host machine:
```bash
flutter build apk --release
```
The output APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.
*(Android build configuration is already pre-configured in `android/app/build.gradle` with release debug-signing enabled for frictionless testing).*

---

## 🔒 Privacy & Offline Guarantee
- **No Firebase or cloud backend:** All data stays 100% on the user's local device.
- **No login or registration:** Open the app and begin tracking immediately.
- **No telemetry or external calls:** Operates completely offline, anywhere, anytime.

---

*Designed and engineered with passion for developers and learners worldwide.*
