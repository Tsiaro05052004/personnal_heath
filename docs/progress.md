# Suivi d'avancement

Journal partagé entre les sessions et les assistants (Claude Code, Codex, Gemini).
**Au début d'une session :** lire ce fichier. **À la fin :** mettre à jour « En cours », « Prochaines étapes » et ajouter une entrée au journal.

## État actuel

Étapes 1 (socle) et 2 (médicaments) faites. Design system des maquettes en place (couleurs, police Atkinson Hyperlegible, cartes, badges). Onglet Médicaments complet : liste du jour avec bandeau de dates, confirmation / « non pris », formulaire en 3 étapes (ajout, modification, suppression). Autres onglets : écrans provisoires au nouveau style. 36 tests.

## En cours

_Rien pour l'instant._

## Prochaines étapes

- [x] Définir les fonctionnalités → `CAHIER DES CHARGES SIMPLIFIÉ.md` (résumé dans `AGENTS.md`)
- [x] Faire compiler l'app Android (`flutter build apk --debug` OK)
- [ ] L'installer et la lancer sur le téléphone (Realme, `flutter run`)
- [x] Valider l'architecture proposée dans `docs/architecture.txt`
- [x] Mettre en place le socle (étape 1)
- [x] Étape 2 : `medications/` (maquettes 3 et 4)
- [ ] Étape 3 : notifications + rappels + écran d'alarme plein écran (maquette 7) — brancher la replanification dans SaveMedication / DeleteMedication / ConfirmIntake
- [ ] Étape 4 : hydratation (maquette 5)
- [ ] Étape 5 : accueil (maquette 2, réutiliser `dayPlanProvider` et `IntakePlanner.nextIntake`)
- [ ] Étape 6 : hôpitaux (maquette 6) · Étape 7 : connexion (maquette 1) + Supabase · Étape 8 : historique (maquette 8) + paramètres
- [ ] Tester l'onglet Médicaments sur le téléphone (`flutter run`)
- [x] Initialiser le dépôt git

## Décisions prises

| Date | Décision | Raison |
|---|---|---|
| 2026-11-07 | `AGENTS.md` = source unique d'instructions ; `CLAUDE.md` et `GEMINI.md` l'importent | Partager le même contexte entre Claude, Codex et Gemini |
| 2026-11-07 | Architecture de `docs/architecture.txt` validée (Riverpod, go_router, Drift, Supabase) | L'utilisateur a demandé de construire l'appli à partir d'elle |
| 2026-11-08 | Interface = `docs/Maquettes app santé.pdf`, réalisée écran par écran dans l'ordre des étapes | Demande de l'utilisateur |
| 2026-11-08 | Police Atkinson Hyperlegible embarquée (pas google_fonts) | Celle des maquettes, conçue pour la basse vision ; doit marcher hors ligne |
| 2026-11-08 | Prise « en attente » 2 h après l'heure, puis « non confirmée » ; confirmation possible 30 min avant | Règles du CDC (non confirmée ≠ oubliée) ; délais à ajuster dans `IntakePlanner` |
| 2026-11-08 | Clean Architecture stricte (use cases, mappers, `di/`) + MVVM (ViewModel `Notifier` + `UiState` immuable par écran) | Demande de l'utilisateur ; règles vérifiées par `test/architecture/dependency_rules_test.dart` |
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

### 2026-11-08
- Audit Clean Architecture + MVVM du socle. Corrections : `AppRoutes` déplacé dans `lib/core/navigation/app_routes.dart` (core dépendait de app/) ; libellé de `MealInstruction` sorti du domaine vers `presentation/mappers/meal_instruction_label.dart`.
- Ajout de `test/architecture/dependency_rules_test.dart` (sens des dépendances entre couches).
- `docs/architecture.txt` révisé : nouvelle arborescence par feature (usecases, mappers, di, viewmodels), section 4 (règles de dépendance), nouvelle section 5 (MVVM), flux « Confirmer la prise » réécrit ; sections renumérotées (ordre de développement = section 10).
- Étape 2 (médicaments) d'après les maquettes : design system (`core/theme`, `core/widgets`), onglet « Carte » renommé « Hôpitaux », bouton profil à la place de l'icône ⚙ ; domaine (`Medication`, `DoseTime`, `IntakeLog`, `DayPlan`, `IntakePlanner`, `MedicationRules`, 7 use cases), data (DAO Drift, mappers, dépôt), `di/`, ViewModels liste + formulaire, écrans. Lignes Drift renommées `*Row`. Tests : domaine, dépôt (base en mémoire), écrans (36 au total).
- Bogues trouvés grâce aux captures d'écran de test : police non appliquée (le `copyWith` du textTheme perdait la famille), fiche du bas qui débordait, formulaire qui gardait le défilement d'une étape à l'autre.
