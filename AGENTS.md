# AGENTS.md

Shared instructions for AI coding agents (Claude Code, Codex, Gemini) working in this repository. This is the single source of truth: CLAUDE.md and GEMINI.md only import this file — edit here.

## Project status

Flutter app `personnal_heath` (personal health tracker — note the package name keeps the "heath" spelling; don't "fix" it in imports, it would break `package:personnal_heath/...`).

The project is currently the unmodified `flutter create` template: `lib/main.dart` holds the counter demo (`MyApp` / `MyHomePage`) and `test/widget_test.dart` is the matching smoke test. No architecture, state management, persistence, or routing has been chosen yet — when one is introduced, record the decision in the "Architecture" section below.

- Dart SDK `^3.13.5`; only dependency beyond Flutter is `cupertino_icons`.
- Lints: `flutter_lints` (`analysis_options.yaml`), with platform folders and `build/` excluded from analysis.
- Platforms scaffolded: android, ios, linux, macos (no web/windows).
- Not yet a git repository.

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
