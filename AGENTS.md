# AGENTS.md

Shared instructions for AI coding agents (Claude Code, Codex, Gemini) working in this repository. This is the single source of truth: CLAUDE.md and GEMINI.md only import this file — edit here.

## Project status

Flutter app `personnal_heath` (personal health tracker — note the package name keeps the "heath" spelling; don't "fix" it in imports, it would break `package:personnal_heath/...`).

Steps 1 (foundation), 2 (`medications/`: CRUD + daily intake tracking) 3 (reminders: scheduled notifications + full-screen alarm screen) 4 (`hydration/`: water goal, glass counter, spread water reminders) 5 (`dashboard/`), 6 (`hospitals/`: OSM map, Overpass, cache, GPS) and 8 (`history/` + `settings/`) are done; 7 (`auth/` + Supabase + `core/sync`) is done too — the whole MVP is built; the other tabs are placeholders. UI follows the mockups in `docs/Maquettes app santé.pdf` (8 screens; open it before building a screen). See `docs/progress.md` for the current step.

- Dart SDK `^3.13.5`; main deps: flutter_riverpod 3, go_router, drift + drift_flutter, intl, uuid.
- Lints: `flutter_lints` (`analysis_options.yaml`), with platform folders and `build/` excluded from analysis.
- Platforms scaffolded: android, ios, linux, macos (no web/windows).
- Git repository, default branch `main` (no remote yet).

## Product spec (summary)

Full spec: `CAHIER DES CHARGES SIMPLIFIÉ.md` at the repo root (French). Read it before designing any feature. Key points:

- **Purpose:** personal health assistant: medication reminders and intake tracking, daily water goal, nearby hospitals map, daily dashboard. Target users include elderly / non-technical people, so the UI must stay very simple.
- **Pages:** Connexion/Inscription, Accueil (daily dashboard), Carte, Mes médicaments, Suivi des médicaments, Hydratation, Historique, Paramètres.
- **MVP (must-have):** auth, dashboard, OpenStreetMap hospital map, medication CRUD + schedules, notifications/alarms, intake counter, water goal + glass counter. Important: daily history. Later: weekly/monthly stats, sharing with a relative, health-professional link, prescriptions photo, appointments, stock alerts.
- **Medication record:** name, dosage (e.g. 500 mg), quantity per intake, frequency (intakes/day), times, start date, end date, instructions (before/after meal).
- **Water:** daily goal in glasses, ml per glass, wake/sleep times used to spread reminders; never push drinking a lot at once.
- **Map:** OpenStreetMap via `flutter_map`, user location with permission, markers for hospitals/clinics/health centres; detail sheet with name, address, type, distance, phone, route; search by name/place. Respect the tile provider's usage policy; OSM data may be outdated.

Business rules that must hold:

- One "intake" (prise) ≠ number of pills: 2 pills at 08:00 = 1 intake, 2 pills consumed.
- Unconfirmed ≠ missed: the app can't know a dose was taken unless the user confirms. Confirming late records the **actual** time; the user can also mark a dose as missed.
- Reminder at the scheduled time → second reminder if still unconfirmed → optional sound alarm if the user allowed it.
- Reminders stop at the treatment end date; editing a treatment reschedules its reminders.
- Water goal reached → success message; day ends below goal → "goal not reached" summary.
- **Never** change doses, suggest doubling a missed dose, or give medical advice: the app is a reminder tool, not a doctor.

Technical constraints: Android first (iOS nice to have); notifications must fire with the app closed; tracking must work offline once configured; health data stored securely, accessible only by its owner, account + data deletable. Suggested backend in the spec: Supabase or Firebase (auth + DB). Not decided yet.

## Commands

```bash
flutter pub get                              # install dependencies
flutter run -d linux                         # run on desktop (dev machine is Linux)
flutter run --dart-define-from-file=supabase.json  # run on the phone WITH the Supabase backend (supabase.json is git-ignored, see supabase.example.json); without it the app runs account-less
flutter analyze                              # lint / static analysis
dart format lib test                         # format
flutter test                                 # all tests
flutter test test/app/app_test.dart          # single test file
flutter test --plain-name "la barre du bas change de page"  # single test by name
dart run build_runner build                  # regenerate Drift code (*.g.dart) after editing tables
flutter build apk --debug                    # Android build (JDK 21 configured via flutter config)
```

## Architecture

**Validated by the user on 2026-11-07, revised 2026-11-08 to strict Clean Architecture + MVVM; being implemented step by step** (order in section 10 of the doc). Full description (French): `docs/architecture.txt`. Read it before adding code.

- Feature-first: `lib/app/` (root widget, go_router, bottom nav shell, theme), `lib/core/` (Drift DB, navigation routes, notifications + reminder scheduler, background tasks, sync, location, permissions, shared widgets), `lib/features/<auth|dashboard|medications|hydration|hospitals|history|settings>/`, each following Clean Architecture:
  - `domain/` (pure Dart: `entities/`, `repositories/` interfaces, `usecases/` one action per class with `call()`, `services/` pure rules);
  - `data/` (`datasources/local|remote`, `mappers/` Drift row/JSON ↔ entity — Drift classes never leave `data/`, `repositories/` impls);
  - `di/<feature>_providers.dart` (Riverpod providers wiring datasources → repo impl → use cases, typed with the domain interface);
  - `presentation/` in MVVM: `viewmodels/` (`Notifier`/`AsyncNotifier` per screen + immutable `UiState`, no Flutter widgets/BuildContext, talks only to use cases), `mappers/` (display labels, e.g. `MealInstructionLabel`), `screens/` + `widgets/` (Views: `ConsumerWidget`, render state, forward actions, no logic).
- Dependency rules (`presentation → domain ← data`, `core ↛ app`, presentation never imports `data/` or Drift, domain never imports packages) are enforced by `test/architecture/dependency_rules_test.dart`. Create a folder only when it holds a file.
- Stack: Riverpod, go_router, Drift (local DB = source of truth, offline-first), Supabase (auth + Postgres with RLS `user_id = auth.uid()`, sync), flutter_local_notifications + timezone + workmanager, flutter_map + Overpass API + geolocator, url_launcher.
- Implemented conventions: bottom tabs = Accueil, Médicaments, Eau, Hôpitaux, Historique; tab screens have no AppBar but a `TabPage` big title; Paramètres is a full-screen route opened from the round profile button on Accueil (`ProfileButton`). Full-screen pages (forms, settings) live outside the shell. Design system in `lib/core/theme/` (`AppColors` from the mockups, `AppTheme`, bundled Atkinson Hyperlegible font) and shared widgets in `lib/core/widgets/` (`AppCard`, `StatusBadge`, `DashedButton`, `PillIcon`…).
- Time: never call `DateTime.now()` in ViewModels; watch `clockProvider` (`lib/core/time/clock.dart`, ticks every minute). Widget tests use `test/helpers/pump_app.dart` (in-memory DB with `closeStreamsSynchronously`, `FixedClock` at 2026-11-08 14:10, phone-sized view).
- Riverpod 3 recreates a Notifier on every rebuild: keep state that must survive (e.g. selected day) in its own provider, and use `ref.read` (not `watch`) in form ViewModels so they don't reset. Route paths live in `AppRoutes` (`lib/core/navigation/app_routes.dart`, so screens/shared widgets don't depend on `app/`); the routes themselves in `lib/app/router.dart`. The DB is exposed by `appDatabaseProvider`; tests override it with `AppDatabase(NativeDatabase.memory())`.
- Deleting a medication only soft-deletes the medication row (`Medication.deletedAt` = its `updatedAt`); schedules stay so history keeps past days. Use `watchMedications(includeDeleted: true)` for history.
- Device-only settings (alarm sound, follow-up delay) live in `shared_preferences` via `reminderPreferencesProvider` (`lib/core/notifications/reminder_preferences.dart`); `pumpApp(preferences: {...})` seeds them in tests.
- Drift row classes are suffixed `Row` (`@DataClassName('MedicationRow')`) so they never clash with domain entities; mappers in `data/mappers/` convert them.
- Drift tables use the `SyncColumns` mixin (UUID `id` via `newId()`, `userId`, `updatedAt`, `deleted`, `dirty`). Times of day are stored as minutes since midnight. Domain enums (`MealInstruction`, `IntakeStatus`) are stored with `textEnum`. Generated `*.g.dart` files are committed.
- Reminders (section 7 of the doc): `ReminderPlanner` (pure rules) → `ReminderGateway` (domain interface) → `NotificationReminderGateway` (data) → `NotificationService` (`lib/core/notifications/`, the only code touching flutter_local_notifications). 14-day rolling window rebuilt on app start/resume and after any treatment change; confirming / marking missed cancels that intake's reminders. Notification taps open `/alarme` (`IntakeAlarmScreen`). Alarm sound is on by default (`alarmSoundEnabledProvider`, separate `alarme_medicaments` channel: alarm ringtone, insistent, 5 min max); Android channel sound can't change after creation, so a new sound needs a new channel id. Keep flutter_local_notifications on 22.x (23 needs compileSdk 37, not resolvable with the installed SDK).
- Shared form widgets (`FormQuestion`, `ChoiceButton`, `QuantityStepper`…) live in `lib/core/widgets/form_widgets.dart`; across features import only `domain/`, `di/` or `presentation/mappers/` (enforced by the architecture test). Cross-feature data goes through `di/` providers (`dayPlanProvider`, `waterDayProvider`).
- Backend: Supabase (schema in `supabase/migrations/`, RLS `user_id = auth.uid()`). Login is mandatory when configured (router redirect). Sync = pull then push in `lib/core/sync/sync_service.dart`; any new synced table needs a spec there, a SQL migration, and RLS. Never put the service_role key in the app.
- Async ViewModel actions that may navigate away (e.g. login) must check `ref.mounted` before touching state.
- Each feature's reminder gateway only touches notifications whose payload `type` is its own (`prise`, `eau`).
- The test phone (Realme RMX2111) is **360 × 800 dp** (density 3); `pumpApp` uses that size — design for it. The bottom bar is a custom `AppNavigationBar` (`lib/app/shell_scaffold.dart`), not Material's `NavigationBar`.
- Widget tests: `pumpApp(auth: FakeAuthRepository(...), syncRemote: FakeSyncRemote())` enables accounts (default: disabled, no login screen); fakes are in `test/helpers/fake_backend.dart`.
- Widget tests: switch tabs with `tapTab(tester, 'Eau')` (tab labels also appear on the home screen); use `tapVisible` / `scrollTo` for anything that may be below the fold. `pumpApp` also fakes GPS (`FakeLocationGateway`), Overpass (`FakeOverpass`, via http `MockClient`), map tiles (off) and `ExternalLauncher`.
- Widget tests: override `notificationServiceProvider` with `FakeNotificationService` (done by `pumpApp`), and use `settle(tester)` instead of bare `pumpAndSettle` after actions that hit the DB — Drift needs real time, not fake time.

## Working notes

- The user writes in French; reply in French.
- Progress between sessions should be tracked in `docs/progress.md`: read it at the start of a session and update it (En cours, Prochaines étapes, Journal) at the end, so later conversations can pick up where the previous one stopped.
