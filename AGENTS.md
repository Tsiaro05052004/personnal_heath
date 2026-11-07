# AGENTS.md

Shared instructions for AI coding agents (Claude Code, Codex, Gemini) working in this repository. This is the single source of truth: CLAUDE.md and GEMINI.md only import this file — edit here.

## Project status

Flutter app `personnal_heath` (personal health tracker — note the package name keeps the "heath" spelling; don't "fix" it in imports, it would break `package:personnal_heath/...`).

The project is currently the unmodified `flutter create` template: `lib/main.dart` holds the counter demo (`MyApp` / `MyHomePage`) and `test/widget_test.dart` is the matching smoke test. No architecture, state management, persistence, or routing has been chosen yet — when one is introduced, record the decision in the "Architecture" section below.

- Dart SDK `^3.13.5`; only dependency beyond Flutter is `cupertino_icons`.
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
flutter test test/widget_test.dart           # single test file
flutter test --plain-name "Counter increments smoke test"   # single test by name
```

## Architecture

_To be defined._ Record here: state-management choice, folder layout under `lib/`, local storage / backend, navigation approach, and the reason for each.

## Working notes

- The user writes in French; reply in French.
- Progress between sessions should be tracked in `docs/progress.md`: read it at the start of a session and update it (En cours, Prochaines étapes, Journal) at the end, so later conversations can pick up where the previous one stopped.
