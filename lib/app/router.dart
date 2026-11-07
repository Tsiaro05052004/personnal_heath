import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/hospitals/presentation/screens/hospitals_map_screen.dart';
import '../features/hydration/presentation/screens/hydration_screen.dart';
import '../features/medications/presentation/screens/medication_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'shell_scaffold.dart';

/// Chemins des pages, pour éviter les chaînes en dur dans les écrans.
abstract final class AppRoutes {
  static const dashboard = '/';
  static const medications = '/medicaments';
  static const hydration = '/hydratation';
  static const map = '/carte';
  static const history = '/historique';
  static const settings = '/parametres';
}

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
          _tab(AppRoutes.map, const HospitalsMapScreen()),
          _tab(AppRoutes.history, const HistoryScreen()),
        ],
      ),
      // Paramètres : hors de la barre du bas, ouvert depuis l'icône ⚙.
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
