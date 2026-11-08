import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnal_heath/core/sync/supabase_sync_remote.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('récupère les changements du plus ancien au plus récent (le curseur de '
      'synchro est la dernière ligne reçue)', () async {
    final requests = <Uri>[];
    final client = SupabaseClient(
      'https://exemple.supabase.co',
      'cle-publique',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request.url);
        return http.Response(
          jsonEncode(<Object>[]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);

    await SupabaseSyncRemote(client)
        .changesSince('medications', 'user-hery', '2026-11-08T10:00:00+00:00');

    expect(requests, hasLength(1));
    final query = requests.single.queryParameters;
    expect(query['order'], 'server_updated_at.asc.nullslast,id.asc.nullslast');
    expect(query['server_updated_at'], 'gt.2026-11-08T10:00:00+00:00');
    expect(query['user_id'], 'eq.user-hery');
  });
}
