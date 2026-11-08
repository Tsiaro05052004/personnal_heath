/// Ce dont la synchronisation a besoin du serveur (Supabase, ou un faux
/// serveur dans les tests).
abstract interface class SyncRemote {
  /// Ajoute ou met à jour des lignes. [onConflict] : colonnes de la clé
  /// naturelle (ex. « medication_id,scheduled_at »), sinon l'id.
  Future<void> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  });

  /// Lignes de [userId] modifiées sur le serveur après [since]
  /// (server_updated_at, texte ISO renvoyé par le serveur), de la plus
  /// ancienne à la plus récente. Toutes si [since] est null.
  Future<List<Map<String, dynamic>>> changesSince(
    String table,
    String userId,
    String? since,
  );
}
