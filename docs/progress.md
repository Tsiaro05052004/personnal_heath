# Suivi d'avancement

Journal partagé entre les sessions et les assistants (Claude Code, Codex, Gemini).
**Au début d'une session :** lire ce fichier. **À la fin :** mettre à jour « En cours », « Prochaines étapes » et ajouter une entrée au journal.

## État actuel

Projet au stade du modèle `flutter create` (compteur de démo). Aucune fonctionnalité métier.

## En cours

_Rien pour l'instant._

## Prochaines étapes

- [ ] Définir les fonctionnalités de l'application (suivi de quelles données de santé ?)
- [ ] Choisir la gestion d'état, le stockage local et la navigation → noter dans `AGENTS.md` (section Architecture)
- [x] Initialiser le dépôt git

## Décisions prises

| Date | Décision | Raison |
|---|---|---|
| 2026-11-07 | `AGENTS.md` = source unique d'instructions ; `CLAUDE.md` et `GEMINI.md` l'importent | Partager le même contexte entre Claude, Codex et Gemini |

## Problèmes connus

_Aucun._

## Journal

### 2026-11-07
- Création de `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` et `docs/progress.md`.
- `git init` (branche `main`) + premier commit.
