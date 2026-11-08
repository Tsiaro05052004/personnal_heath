import '../../../core/database/local_data_admin.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../domain/repositories/session_data.dart';

/// Données du téléphone ↔ compte : base locale, synchronisation, rappels.
class SessionDataImpl implements SessionData {
  SessionDataImpl({
    required this.admin,
    required this.sync,
    required this.rescheduleReminders,
  });

  final LocalDataAdmin admin;

  /// null si l'appli tourne sans serveur.
  final SyncCoordinator? sync;

  /// Recalcule tous les rappels (médicaments et eau) d'après la base.
  final Future<void> Function() rescheduleReminders;

  @override
  Future<void> attachTo(String userId) async {
    final wiped = await admin.claimFor(userId);
    if (wiped) await sync?.forgetProgress();
    // Récupère aussi les données déjà sauvegardées (autre téléphone).
    await sync?.syncNow();
    await rescheduleReminders();
  }

  @override
  Future<bool> syncNow() async => await sync?.syncNow() ?? true;

  @override
  Future<void> clear() async {
    await sync?.forgetProgress();
    await admin.wipeHealthData();
    // Base vide : plus aucun rappel.
    await rescheduleReminders();
  }
}
