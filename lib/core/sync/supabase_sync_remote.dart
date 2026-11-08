import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_remote.dart';

/// Synchronisation avec les tables Supabase (protégées par RLS : chacun ne
/// voit que ses lignes).
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;

  static const _pageSize = 500;

  @override
  Future<void> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  }) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert(rows, onConflict: onConflict);
  }

  @override
  Future<List<Map<String, dynamic>>> changesSince(
    String table,
    String userId,
    String? since,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += _pageSize) {
      // La RLS ne renvoie déjà que nos lignes ; le filtre explicite est une
      // sécurité de plus.
      var query = _client.from(table).select().eq('user_id', userId);
      if (since != null) query = query.gt('server_updated_at', since);
      // Du plus ancien au plus récent : la dernière ligne sert de curseur.
      // (`order` de Postgrest est décroissant par défaut en Dart.)
      final page = await query
          .order('server_updated_at', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + _pageSize - 1);
      result.addAll(page);
      if (page.length < _pageSize) return result;
    }
  }
}
