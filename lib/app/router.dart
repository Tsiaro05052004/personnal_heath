import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/app_routes.dart';
import '../features/auth/di/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/password_reset_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
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

/// Toutes les routes de l'application. Connexion obligatoire (choix de
/// l'utilisateur, 2026-11-08) : sans compte, toute page mène à /connexion ;
/// une fois connecté, les pages de compte mènent à l'Accueil.
final routerProvider = Provider<GoRouter>((ref) {
  final authEnabled = ref.watch(authEnabledProvider);
  // Recalcule la redirection à chaque connexion / déconnexion.
  final authChanges = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: authChanges,
    redirect: (context, state) {
      if (!authEnabled) return null;
      final signedIn = ref.read(authRepositoryProvider).currentUser != null;
      final onAuthPage = AppRoutes.authPages.contains(state.matchedLocation);
      if (!signedIn && !onAuthPage) return AppRoutes.login;
      if (signedIn && onAuthPage) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        builder: (context, state) => const PasswordResetScreen(),
      ),
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
