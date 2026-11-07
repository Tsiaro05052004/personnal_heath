# AGENTS.md

Shared instructions for AI coding agents (Claude Code, Codex, Gemini) working in this repository. This is the single source of truth: CLAUDE.md and GEMINI.md only import this file — edit here.

## Project status

Flutter app `personnal_heath` (personal health tracker — note the package name keeps the "heath" spelling; don't "fix" it in imports, it would break `package:personnal_heath/...`).

Step 1 of the architecture (foundation) is done: theme, go_router shell with 5 bottom tabs, Drift database with all tables, placeholder screens per feature. No business feature is implemented yet; see `docs/progress.md` for the current step.

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
flutter run                                  # run on an attached device/emulator
flutter analyze                              # lint / static analysis
dart format lib test                         # format
flutter test                                 # all tests
flutter test test/app/app_test.dart          # single test file
flutter test --plain-name "la barre du bas change de page"  # single test by name
dart run build_runner build                  # regenerate Drift code (*.g.dart) after editing tables
flutter build apk --debug                    # Android build (JDK 21 configured via flutter config)
```

## Architecture

**Validated by the user on 2026-11-07; being implemented step by step** (order in section 9 of the doc). Full description (French): `docs/architecture.txt`. Read it before adding code.

- Feature-first: `lib/app/` (root widget, go_router, bottom nav shell, theme), `lib/core/` (Drift DB, notifications + reminder scheduler, background tasks, sync, location, permissions, shared widgets), `lib/features/<auth|dashboard|medications|hydration|hospitals|history|settings>/` each split into `data/` (local DAO, remote, repository impl), `domain/` (pure-Dart entities, repository interface, business-rule services), `presentation/` (Riverpod providers, screens, widgets).
- Stack: Riverpod, go_router, Drift (local DB = source of truth, offline-first), Supabase (auth + Postgres with RLS `user_id = auth.uid()`, sync), flutter_local_notifications + timezone + workmanager, flutter_map + Overpass API + geolocator, url_launcher.
- Implemented conventions: bottom tabs = Accueil, Médicaments, Eau, Carte, Historique; Paramètres is a full-screen route opened from the ⚙ app-bar icon (`SettingsAction`). Route paths live in `AppRoutes` (`lib/app/router.dart`). The DB is exposed by `appDatabaseProvider`; tests override it with `AppDatabase(NativeDatabase.memory())`.
- Drift tables use the `SyncColumns` mixin (UUID `id` via `newId()`, `userId`, `updatedAt`, `deleted`, `dirty`). Times of day are stored as minutes since midnight. Domain enums (`MealInstruction`, `IntakeStatus`) are stored with `textEnum`. Generated `*.g.dart` files are committed.
- Reminders are OS-scheduled over a rolling 2–3 day window and rebuilt on app start, on treatment/water changes, daily, and after reboot. Confirming an intake cancels its follow-up reminder and alarm.

## Working notes

- The user writes in French; reply in French.
- Progress between sessions should be tracked in `docs/progress.md`: read it at the start of a session and update it (En cours, Prochaines étapes, Journal) at the end, so later conversations can pick up where the previous one stopped.
