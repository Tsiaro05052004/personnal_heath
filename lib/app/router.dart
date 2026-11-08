import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/app_routes.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/hospitals/presentation/screens/hospitals_map_screen.dart';
import '../features/hydration/presentation/screens/hydration_screen.dart';
import '../features/hydration/presentation/screens/water_goal_screen.dart';
import '../features/medications/presentation/screens/intake_alarm_screen.dart';
import '../features/medications/presentation/screens/medication_form_screen.dart';
import '../features/medications/presentation/screens/medication_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'shell_scaffold.dart';

/// Toutes les routes de l'application.
/// À venir (étape 7) : redirection vers /connexion si non connecté.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScaffold(shell: shell),
        branches: [
          _tab(AppRoutes.dashboard, const DashboardScreen()),
          _tab(AppRoutes.medications, const MedicationListScreen()),
          _tab(AppRoutes.hydration, const HydrationScreen()),
          _tab(AppRoutes.hospitals, const HospitalsMapScreen()),
          _tab(AppRoutes.history, const HistoryScreen()),
        ],
      ),
      // Pages plein écran, sans la barre du bas.
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.waterGoal,
        builder: (context, state) => const WaterGoalScreen(),
      ),
      // Déclarée avant « /medicament/:id » pour ne pas être prise pour un id.
      GoRoute(
        path: AppRoutes.newMedication,
        builder: (context, state) => const MedicationFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.intakeAlarm,
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return IntakeAlarmScreen(
            target: (
              medicationId: query['med'] ?? '',
              scheduledAt: DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(query['at'] ?? '') ?? 0,
              ),
            ),
            action: query['action'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.medicationPattern,
        builder: (context, state) =>
            MedicationFormScreen(medicationId: state.pathParameters['id']),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
