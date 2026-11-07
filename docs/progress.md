# Suivi d'avancement

Journal partagé entre les sessions et les assistants (Claude Code, Codex, Gemini).
**Au début d'une session :** lire ce fichier. **À la fin :** mettre à jour « En cours », « Prochaines étapes » et ajouter une entrée au journal.

## État actuel

Projet au stade du modèle `flutter create` (compteur de démo). Aucune fonctionnalité métier.

## En cours

_Rien pour l'instant._

## Prochaines étapes

- [x] Définir les fonctionnalités → `CAHIER DES CHARGES SIMPLIFIÉ.md` (résumé dans `AGENTS.md`)
- [ ] Faire compiler l'app sur le téléphone Android (voir Problèmes connus)
- [ ] Valider l'architecture proposée dans `docs/architecture.txt` (Riverpod, go_router, Drift, Supabase…)
- [ ] Mettre en place le socle (étape 1 de la section 9 de `docs/architecture.txt`)
- [x] Initialiser le dépôt git

## Décisions prises

| Date | Décision | Raison |
|---|---|---|
| 2026-11-07 | `AGENTS.md` = source unique d'instructions ; `CLAUDE.md` et `GEMINI.md` l'importent | Partager le même contexte entre Claude, Codex et Gemini |

## Problèmes connus

- **Build Android échoue** : `Toolchain installation '/usr/lib/jvm/java-25-openjdk' does not provide the required capabilities: [JAVA_COMPILER]`. Seul le JRE Java 25 (headless) est installé, sans `javac`. Correctif : `sudo dnf install java-21-openjdk-devel` puis `flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk`.
- `flutter doctor` : `cmdline-tools` Android manquant, licences non acceptées ; `clang++` et `ninja` manquants pour la cible Linux desktop.

## Journal

### 2026-11-07
- Création de `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` et `docs/progress.md`.
- `git init` (branche `main`) + premier commit.
- Ajout du cahier des charges, résumé dans `AGENTS.md`.
- Diagnostic du build Android : JDK sans compilateur (voir Problèmes connus). Téléphone de test : Realme RMX2111, Android 12 (API 31).
- Proposition d'architecture rédigée dans `docs/architecture.txt` (en attente de validation).
