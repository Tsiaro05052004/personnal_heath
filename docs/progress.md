# Suivi d'avancement

Journal partagé entre les sessions et les assistants (Claude Code, Codex, Gemini).
**Au début d'une session :** lire ce fichier. **À la fin :** mettre à jour « En cours », « Prochaines étapes » et ajouter une entrée au journal.

## État actuel

Toutes les étapes du MVP sont faites (1 à 8) : socle, médicaments, rappels + écran d'alarme, hydratation, accueil, carte des hôpitaux, connexion + Supabase + synchronisation, historique et paramètres. Design system des maquettes en place (couleurs, police Atkinson Hyperlegible, cartes, badges). Onglet Médicaments complet : liste du jour avec bandeau de dates, confirmation / « non pris », formulaire en 3 étapes (ajout, modification, suppression). Autres onglets : écrans provisoires au nouveau style. 140 tests.

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
- [x] Étape 4 : hydratation (maquette 5)
- [x] Essayer l'onglet Eau sur le Realme (objectif, verres, rappels d'eau)
- [x] Étape 5 : accueil (maquette 2)
- [x] Étape 6 : hôpitaux (maquette 6)
- [x] Essayer la carte sur le Realme avec la localisation activée (validé par l'utilisateur)
- [x] Étape 8 : historique (maquette 8) + paramètres (faite avant la 7)
- [x] Étape 7 : connexion (maquette 1) + Supabase + synchronisation
- [ ] Supabase : modèle d'e-mail « Reset Password » avec {{ .Token }} (code à 6 chiffres) — à faire par l'utilisateur
- [ ] Essayer sur le Realme : inscription, connexion, sauvegarde, 2e téléphone ou réinstallation, mot de passe oublié, déconnexion, suppression du compte
- [ ] À décider : désactiver la sauvegarde automatique Android (`allowBackup` non défini : base de santé et session incluses par défaut)
- [ ] Mot de passe oublié : après un code valide, le routeur quitte l'écran avant le changement du mot de passe ; un refus du serveur à ce moment n'est pas affiché
- [ ] Avant publication : identifiant d'appli définitif (pas com.example), réactiver « Confirm email », service d'envoi d'e-mails, fournisseur de tuiles de carte
- [ ] Avant publication : fournisseur de tuiles de carte compatible avec un usage public
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
| 2026-11-08 | Rappels d'eau : 8/jour max avec objectif intermédiaire, bilan 30 min avant le coucher, simple notification | CDC 2.3 C : encourager à boire régulièrement, jamais beaucoup d'un coup |
| 2026-11-08 | Carte : OpenStreetMap (flutter_map) + API Overpass, cache local, recherche 5 puis 20 km | CDC 2.1 ; hors ligne avec la dernière liste |
| 2026-11-08 | Tests et captures à 360 × 800 dp | Taille réelle du Realme (densité 3) : les écrans à 411 dp cachaient des débordements |
| 2026-11-08 | Barre du bas sur mesure (AppNavigationBar) | NavigationBar coupait « Médicaments » sur deux lignes à 360 dp |
| 2026-11-08 | Supabase confirmé (pas Firebase) ; connexion obligatoire | Choix de l'utilisateur |
| 2026-11-08 | Mot de passe oublié par code à 6 chiffres | Pas de lien profond à gérer ; plus simple sur téléphone |
| 2026-11-08 | Déconnexion = effacement des données du téléphone | Téléphone partagé : le suivant ne doit rien voir (données sauvegardées avant) |
| 2026-11-08 | Étape 8 avant l'étape 7 | L'étape 7 attend un projet Supabase (choix de l'utilisateur) |
| 2026-11-08 | Médicament supprimé gardé dans l'historique (deletedAt) | Un historique de santé ne doit pas perdre les prises passées |
| 2026-11-08 | Réglages des rappels dans shared_preferences | Propres au téléphone, pas besoin de synchronisation |
| 2026-11-08 | Workmanager reporté | Chaque rappel touché rouvre l'appli et prolonge la fenêtre ; à réévaluer après essai sur téléphone |
| 2026-11-08 | Clean Architecture stricte (use cases, mappers, `di/`) + MVVM (ViewModel `Notifier` + `UiState` immuable par écran) | Demande de l'utilisateur ; règles vérifiées par `test/architecture/dependency_rules_test.dart` |
| 2026-11-07 | Onglets : Accueil, Médicaments, Eau, Carte, Historique ; Paramètres via l'icône ⚙ | 5 onglets maximum pour rester simple |

## Problèmes connus

- Lancer l'appli AVEC le serveur : `flutter run --dart-define-from-file=supabase.json` (sinon, appli sans compte).

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
- Étape 4 (branche `etape-4-hydratation`) : feature `hydration/` complète (domaine, data, di, ViewModels, écrans « Mon eau du jour » et « Mon objectif d'eau »), rappels d'eau sur le canal « rappels_eau », toucher → onglet Eau, replanification au démarrage/retour (médicaments puis eau). Éléments de formulaire déplacés dans `core/widgets/form_widgets.dart` (partagés). `settle()` des tests rendu robuste aux indicateurs de chargement. 89 tests. Essayé sur le Realme : objectif, verres, rappels d'eau OK.
- Étape 5 (branche `etape-5-accueil`) : feature `dashboard/` (DailySummaryCalculator, DashboardViewModel, carte « Prochaine prise », compteurs, liste « Aujourd'hui »). « Bonjour » sans prénom jusqu'à l'étape 7. Nouvelle règle d'architecture testée : entre features, seulement domain/, di/ et presentation/mappers/. Captures : badges coupés au milieu des mots et « Médicaments » sur deux lignes, corrigés. Outil de test `tapTab()` (les libellés d'onglets apparaissent aussi sur l'Accueil). 89 tests. Essayé sur le Realme : OK.
- Étape 6 (branche `etape-6-hopitaux`) : feature `hospitals/` complète (Overpass, cache, GPS, carte, recherche, filtres, fiche, Itinéraire / Appeler), permissions Android (INTERNET, localisation) et <queries>. Sur le Realme : la carte s'affiche ; la localisation du téléphone était désactivée, l'explication s'affiche bien. Le Realme fait 360 dp de large (densité 3) : tests et captures passés à 360 × 800 dp, ce qui a révélé et fait corriger plusieurs débordements (barre du bas sur mesure, ligne « Confirmer », boutons de la fiche, filtres). Mention OpenStreetMap fixée en pied de fiche (toujours visible). Outils de test `scrollTo()` / `tapVisible()` qui font défiler la page. 105 tests.
- Étape 8 (branche `etape-8-historique-parametres`) : historique (HistoryCalculator, semaine / mois, détail d'un jour, « en retard », médicaments supprimés gardés pour les jours d'avant) et paramètres (alarme sonore, délai du 2e rappel 15/30/60 min, autorisations, aide arrière-plan, lien objectif d'eau). shared_preferences ajouté. Correction a11y : compteurs fusionnés pour les lecteurs d'écran. 119 tests. Installé sur le Realme.
- Étape 7 (branche `etape-7-connexion`) : projet Supabase créé par l'utilisateur, script SQL exécuté (vérifié : anon refusé partout, confirmation e-mail désactivée). Feature `auth/` (connexion, inscription, code de réinitialisation, déconnexion avec effacement local, suppression du compte), `core/sync` (récupérer puis envoyer, la plus récente gagne, clé naturelle des prises, un seul objectif d'eau), synchro automatique, « Bonjour, prénom », rubrique Compte. Bogue trouvé par les tests : ViewModel détruit pendant la connexion (vérifier `ref.mounted`). 135 tests, dont deux téléphones sur un même compte. APK construit avec supabase.json ; pas encore essayé sur le Realme.
- Correctifs étape 7, trouvés en relisant le code réel (les faux serveurs des tests les masquaient) : (1) `order()` de Postgrest est décroissant par défaut en Dart → curseur bloqué sur la ligne la plus ancienne, mêmes lignes récupérées à chaque synchro, relance et replanification en boucle ; tri croissant explicite. (2) Curseurs conservés après l'effacement de la base → données absentes après déconnexion + reconnexion ; `forgetCursors` / `forgetProgress`. (3) Session fermée AVANT l'effacement (déconnexion, suppression du compte), et attente de la synchro en cours, pour ne pas re-télécharger les données effacées. 140 tests. Essai en debug sur le Realme avec le serveur Supabase : concluant d'après l'utilisateur (détail des parcours non précisé).
