import 'dart:async';

import 'package:personnal_heath/core/sync/sync_remote.dart';
import 'package:personnal_heath/features/auth/domain/entities/app_user.dart';
import 'package:personnal_heath/features/auth/domain/entities/auth_failure.dart';
import 'package:personnal_heath/features/auth/domain/repositories/auth_repository.dart';

/// Faux serveur Supabase : tables en mémoire, server_updated_at posé par
/// le « serveur », clé naturelle des prises (medication_id, scheduled_at).
class FakeSyncRemote implements SyncRemote {
  final tables = <String, Map<String, Map<String, dynamic>>>{};
  var _clock = DateTime.utc(2026, 11, 8);
  bool online = true;
  int upserts = 0;

  String _now() {
    _clock = _clock.add(const Duration(milliseconds: 1));
    return _clock.toIso8601String();
  }

  List<Map<String, dynamic>> rows(String table) =>
      (tables[table] ?? {}).values.toList();

  @override
  Future<void> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  }) async {
    if (!online) throw Exception('hors connexion');
    upserts++;
    final t = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      if (onConflict != null) {
        final keys = onConflict.split(',');
        t.removeWhere(
          (_, existing) => keys.every((k) => existing[k] == row[k]),
        );
      }
      t[row['id'] as String] = {...row, 'server_updated_at': _now()};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> changesSince(
    String table,
    String userId,
    String? since,
  ) async {
    if (!online) throw Exception('hors connexion');
    final list =
        (tables[table] ?? {}).values
            // Comme la RLS de Supabase : seulement les lignes du compte.
            .where((r) => r['user_id'] == userId)
            .where(
              (r) =>
                  since == null ||
                  (r['server_updated_at'] as String).compareTo(since) > 0,
            )
            .toList()
          ..sort(
            (a, b) => (a['server_updated_at'] as String).compareTo(
              b['server_updated_at'] as String,
            ),
          );
    return list.map((r) => {...r}).toList();
  }
}

/// Faux service de comptes. Code de réinitialisation : 123456.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedIn}) : _user = signedIn {
    if (signedIn != null) {
      _accounts[signedIn.email] = (signedIn, 'motdepasse');
    }
  }

  static const hery = AppUser(
    id: 'user-hery',
    email: 'hery@mail.com',
    displayName: 'Hery',
  );

  final _accounts = <String, (AppUser, String)>{};
  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  bool online = true;
  bool deleted = false;
  String? codeSentTo;

  void addAccount(AppUser user, String password) =>
      _accounts[user.email] = (user, password);

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  void _checkOnline() {
    if (!online) throw const AuthError(AuthFailure.network);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchUser() => _changes.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    _checkOnline();
    final account = _accounts[email];
    if (account == null || account.$2 != password) {
      throw const AuthError(AuthFailure.invalidCredentials);
    }
    _set(account.$1);
    return account.$1;
  }

  @override
  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _checkOnline();
    if (_accounts.containsKey(email)) {
      throw const AuthError(AuthFailure.emailAlreadyUsed);
    }
    final user = AppUser(
      id: 'user-$email',
      email: email,
      displayName: displayName,
    );
    _accounts[email] = (user, password);
    _set(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetCode(String email) async {
    _checkOnline();
    codeSentTo = email;
  }

  @override
  Future<AppUser> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _checkOnline();
    final account = _accounts[email];
    if (code != '123456' || account == null) {
      throw const AuthError(AuthFailure.invalidCode);
    }
    _accounts[email] = (account.$1, newPassword);
    _set(account.$1);
    return account.$1;
  }

  @override
  Future<void> deleteAccount() async {
    _checkOnline();
    deleted = true;
    _accounts.remove(_user?.email);
  }

  @override
  Future<void> signOut() async => _set(null);
}
