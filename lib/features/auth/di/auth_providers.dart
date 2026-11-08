import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/supabase_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_data_admin.dart';
import '../../../core/preferences/preferences_store.dart';
import '../../../core/sync/supabase_sync_remote.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_remote.dart';
import '../../../core/sync/sync_service.dart';
import '../../hydration/di/hydration_providers.dart';
import '../../medications/di/medications_providers.dart';
import '../data/no_backend_auth_repository.dart';
import '../data/session_data_impl.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/session_data.dart';
import '../domain/usecases/auth_usecases.dart';

/// Comptes activés ? (Non sans configuration Supabase : l'appli marche
/// alors sans connexion.) Les tests le remplacent.
final authEnabledProvider = Provider<bool>(
  (ref) => ref.watch(supabaseClientProvider) != null,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const NoBackendAuthRepository()
      : SupabaseAuthRepository(client);
});

/// Utilisateur connecté (null = personne), mis à jour à chaque connexion
/// ou déconnexion.
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final auth = ref.watch(authRepositoryProvider);
  yield auth.currentUser;
  yield* auth.watchUser();
});

// ------------------------------------------------------- Synchronisation

final syncRemoteProvider = Provider<SyncRemote?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseSyncRemote(client);
});

/// Synchronisation automatique ; null sans serveur.
final syncCoordinatorProvider = Provider<SyncCoordinator?>((ref) {
  final remote = ref.watch(syncRemoteProvider);
  if (remote == null) return null;
  final coordinator = SyncCoordinator(
    db: ref.watch(appDatabaseProvider),
    service: SyncService(
      ref.watch(appDatabaseProvider),
      remote,
      ref.watch(sharedPreferencesProvider),
    ),
    currentUserId: () => ref.read(authRepositoryProvider).currentUser?.id,
    onRemoteChanges: () => rescheduleAllReminders(ref),
  )..start();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// Recalcule tous les rappels (médicaments et eau) d'après la base.
Future<void> rescheduleAllReminders(Ref ref) async {
  await ref.read(rescheduleRemindersProvider)();
  await ref.read(rescheduleWaterRemindersProvider)();
}

final sessionDataProvider = Provider<SessionData>(
  (ref) => SessionDataImpl(
    admin: LocalDataAdmin(ref.watch(appDatabaseProvider)),
    sync: ref.watch(syncCoordinatorProvider),
    rescheduleReminders: () => rescheduleAllReminders(ref),
  ),
);

// --------------------------------------------------------------- Use cases

final signInProvider = Provider(
  (ref) =>
      SignIn(ref.watch(authRepositoryProvider), ref.watch(sessionDataProvider)),
);
final signUpProvider = Provider(
  (ref) =>
      SignUp(ref.watch(authRepositoryProvider), ref.watch(sessionDataProvider)),
);
final sendPasswordResetCodeProvider = Provider(
  (ref) => SendPasswordResetCode(ref.watch(authRepositoryProvider)),
);
final resetPasswordProvider = Provider(
  (ref) => ResetPassword(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionDataProvider),
  ),
);
final signOutProvider = Provider(
  (ref) => SignOut(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionDataProvider),
  ),
);
final deleteAccountProvider = Provider(
  (ref) => DeleteAccount(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionDataProvider),
  ),
);
