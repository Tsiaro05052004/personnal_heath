# Suivi d'avancement

Journal partagé entre les sessions et les assistants (Claude Code, Codex, Gemini).
**Au début d'une session :** lire ce fichier. **À la fin :** mettre à jour « En cours », « Prochaines étapes » et ajouter une entrée au journal.

## État actuel

Étapes 1 (socle), 2 (médicaments) et 3 (rappels + écran d'alarme) faites. Design system des maquettes en place (couleurs, police Atkinson Hyperlegible, cartes, badges). Onglet Médicaments complet : liste du jour avec bandeau de dates, confirmation / « non pris », formulaire en 3 étapes (ajout, modification, suppression). Autres onglets : écrans provisoires au nouveau style. 56 tests.

## En cours

_Rien pour l'instant._

## Prochaines étapes

- [x] Définir les fonctionnalités → `CAHIER DES CHARGES SIMPLIFIÉ.md` (résumé dans `AGENTS.md`)
- [x] Faire compiler l'app Android (`flutter build apk --debug` OK)
- [ ] L'installer et la lancer sur le téléphone (Realme, `flutter run`)
- [x] Valider l'architecture proposée dans `docs/architecture.txt`
- [x] Mettre en place le socle (étape 1)
- [x] Étape 2 : `medications/` (maquettes 3 et 4)
- [x] Étape 3 : notifications + rappels + écran d'alarme plein écran (maquette 7)
- [ ] Tester les rappels sur le Realme : appli fermée, téléphone verrouillé, après redémarrage, optimisation de batterie
- [ ] Rafraîchissement quotidien des rappels en arrière-plan (workmanager), si les tests sur téléphone le justifient
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
| 2026-11-08 | Rappels : fenêtre de 14 jours (max 300), 2e rappel à +30 min, « plus tard » = 10 min | CDC ; valeurs dans `ReminderPlanner` |
| 2026-11-08 | flutter_local_notifications 22.3.3 (pas 23) | La 23 exige compileSdk 37 ; le SDK installé l'a sous le nom `android-37.0`, que AGP 9.1 ne trouve pas |
| 2026-11-08 | Bouton « J'ai pris » de la notification ouvre l'appli | Traitement dans l'appli (base locale) plutôt que dans un isolate de fond : plus simple et plus fiable |
| 2026-11-08 | Rappels en mode « réveil » (setAlarmClock) | Seul mode non retardé par ColorOS ; icône de réveil dans la barre d'état |
| 2026-11-08 | Alarme sonore activée par défaut (sonnerie de réveil répétée, 5 min max) | Choix de l'utilisateur ; interrupteur prévu à l'étape 8 |
| 2026-11-08 | Workmanager reporté | Chaque rappel touché rouvre l'appli et prolonge la fenêtre ; à réévaluer après essai sur téléphone |
| 2026-11-08 | Clean Architecture stricte (use cases, mappers, `di/`) + MVVM (ViewModel `Notifier` + `UiState` immuable par écran) | Demande de l'utilisateur ; règles vérifiées par `test/architecture/dependency_rules_test.dart` |
| 2026-11-07 | Onglets : Accueil, Médicaments, Eau, Carte, Historique ; Paramètres via l'icône ⚙ | 5 onglets maximum pour rester simple |

## Problèmes connus

- ~~Build Android échoue (JDK sans compilateur)~~ : résolu, JDK 21 installé et configuré (`flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk`).
- Realme (ColorOS) retarde les alarmes « exactes » jusqu'à 1 h : résolu en planifiant en mode « réveil » (`AndroidScheduleMode.alarmClock`). Diagnostic : `adb shell dumpsys alarm` → `window=+1h` au lieu de `window=0`.
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
- Étape 3 (branche `etape-3-rappels`) : `core/notifications` (interface + flutter_local_notifications + fuseau horaire), `ReminderPlanner`, `ReminderGateway` + implémentation, use cases `RescheduleReminders` / `SnoozeReminder`, rappels branchés dans les use cases existants, écran d'alarme (maquette 7), notifications touchées → écran d'alarme, demande d'autorisation expliquée après l'ajout d'un médicament. Android : permissions, récepteurs, désucrage, nom de l'appli « Ma Santé ». Tests : 56 (faux service de notifications ; `settle()` dans `test/helpers/pump_app.dart` car Drift a besoin de temps réel en test de widget).
- Essai sur le Realme : aucune alarme. Causes trouvées avec adb : ColorOS ajoutait jusqu'à 1 h de délai aux alarmes exactes, et rouvrir l'appli à l'heure pile annulait le rappel encore non livré (horloge arrondie à la minute). Corrigé : mode « réveil », rappels dus conservés, `scheduleVersion` pour forcer la replanification. Vérifié sur le téléphone : `window=0`, prochain réveil annoncé par Android.
- Alarme sonore (demande de l'utilisateur : le rappel s'affichait sans sonner) : canal « alarme_medicaments » (sonnerie de réveil, USAGE_ALARM, répétition, 5 min max). Vérifié sur le Realme : à 13h05 Android a ouvert l'écran d'alarme de lui-même, ce qui coupait la sonnerie dans la seconde → la sonnerie ne s'arrête plus à l'ouverture de l'écran, seulement sur une réponse ou en le quittant. 63 tests.
