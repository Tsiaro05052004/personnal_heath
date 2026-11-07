# Suivi d'avancement

Journal partagé entre les sessions et les assistants (Claude Code, Codex, Gemini).
**Au début d'une session :** lire ce fichier. **À la fin :** mettre à jour « En cours », « Prochaines étapes » et ajouter une entrée au journal.

## État actuel

Socle en place (étape 1 de `docs/architecture.txt`, section 9) : thème « grands boutons », navigation à 5 onglets + Paramètres, base Drift avec toutes les tables, écrans provisoires. L'APK debug se construit. Aucune fonctionnalité métier encore.

## En cours

_Rien pour l'instant._

## Prochaines étapes

- [x] Définir les fonctionnalités → `CAHIER DES CHARGES SIMPLIFIÉ.md` (résumé dans `AGENTS.md`)
- [x] Faire compiler l'app Android (`flutter build apk --debug` OK)
- [ ] L'installer et la lancer sur le téléphone (Realme, `flutter run`)
- [x] Valider l'architecture proposée dans `docs/architecture.txt`
- [x] Mettre en place le socle (étape 1)
- [ ] Étape 2 : `medications/` (entités, dépôt, liste, formulaire ajout/modification, suivi du jour + « Confirmer la prise »)
- [x] Initialiser le dépôt git

## Décisions prises

| Date | Décision | Raison |
|---|---|---|
| 2026-11-07 | `AGENTS.md` = source unique d'instructions ; `CLAUDE.md` et `GEMINI.md` l'importent | Partager le même contexte entre Claude, Codex et Gemini |
| 2026-11-07 | Architecture de `docs/architecture.txt` validée (Riverpod, go_router, Drift, Supabase) | L'utilisateur a demandé de construire l'appli à partir d'elle |
| 2026-11-07 | Onglets : Accueil, Médicaments, Eau, Carte, Historique ; Paramètres via l'icône ⚙ | 5 onglets maximum pour rester simple |

## Problèmes connus

- ~~Build Android échoue (JDK sans compilateur)~~ : résolu, JDK 21 installé et configuré (`flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk`).
- `flutter doctor` : `cmdline-tools` Android manquant, licences non acceptées ; `clang++` et `ninja` manquants pour la cible Linux desktop.

## Journal

### 2026-11-07
- Création de `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` et `docs/progress.md`.
- `git init` (branche `main`) + premier commit.
- Ajout du cahier des charges, résumé dans `AGENTS.md`.
- Diagnostic du build Android : JDK sans compilateur (voir Problèmes connus). Téléphone de test : Realme RMX2111, Android 12 (API 31).
- Proposition d'architecture rédigée dans `docs/architecture.txt` (en attente de validation).
- Architecture validée. Étape 1 (socle) réalisée : dépendances (flutter_riverpod 3, go_router, drift, intl, uuid), `lib/app/` (thème, routeur, barre du bas), `lib/core/database/` (6 tables + `SyncColumns`), écrans provisoires, 6 tests (navigation + base). `flutter analyze` propre, `flutter build apk --debug` OK.
- Résumé détaillé de la session : `docs/sessions/2026-11-07-socle.md`.
