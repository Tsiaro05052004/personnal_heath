import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/entities/app_user.dart';
import '../domain/entities/auth_failure.dart';
import '../domain/repositories/auth_repository.dart';

/// Comptes avec Supabase Auth (mots de passe hachés par Supabase, session
/// gardée sur le téléphone).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static AppUser? _toUser(User? u) => u == null
      ? null
      : AppUser(
          id: u.id,
          email: u.email ?? '',
          displayName: (u.userMetadata?['display_name'] as String?)?.trim(),
        );

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() =>
      _auth.onAuthStateChange.map((state) => _toUser(state.session?.user));

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _guard(() async {
        final res = await _auth.signInWithPassword(
          email: email,
          password: password,
        );
        return _toUser(res.user)!;
      });

  @override
  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      // Lu par le déclencheur handle_new_user → table profiles.
      data: {'display_name': displayName},
    );
    final user = _toUser(res.user);
    // Inscription avec un e-mail déjà utilisé : Supabase renvoie un
    // utilisateur sans identité (pour ne pas révéler les comptes).
    if (user == null || (res.user?.identities?.isEmpty ?? false)) {
      throw const AuthError(AuthFailure.emailAlreadyUsed);
    }
    if (res.session == null) {
      // Confirmation par e-mail activée sur le projet : pas encore de
      // session. (Désactivée pour l'instant, voir docs/progress.md.)
      throw const AuthError(AuthFailure.unknown);
    }
    return user;
  });

  @override
  Future<void> sendPasswordResetCode(String email) =>
      _guard(() => _auth.resetPasswordForEmail(email));

  @override
  Future<AppUser> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _guard(() async {
    await _auth.verifyOTP(type: OtpType.recovery, email: email, token: code);
    final res = await _auth.updateUser(UserAttributes(password: newPassword));
    return _toUser(res.user)!;
  });

  @override
  Future<void> deleteAccount() =>
      _guard(() => _client.rpc<void>('delete_my_account'));

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Hors connexion ou compte déjà supprimé : on oublie quand même la
      // session sur le téléphone.
      await _auth.signOut(scope: SignOutScope.local);
    }
  }

  /// Traduit les erreurs Supabase en erreurs du domaine.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthError {
      rethrow;
    } on AuthRetryableFetchException {
      throw const AuthError(AuthFailure.network);
    } on AuthException catch (e) {
      throw AuthError(switch (e.code) {
        'invalid_credentials' => AuthFailure.invalidCredentials,
        'user_already_exists' || 'email_exists' => AuthFailure.emailAlreadyUsed,
        'weak_password' => AuthFailure.weakPassword,
        'email_address_invalid' ||
        'validation_failed' => AuthFailure.invalidEmail,
        'otp_expired' || 'otp_disabled' => AuthFailure.invalidCode,
        'over_email_send_rate_limit' ||
        'over_request_rate_limit' => AuthFailure.tooManyAttempts,
        _ => AuthFailure.unknown,
      });
    } on SocketException {
      throw const AuthError(AuthFailure.network);
    } on TimeoutException {
      throw const AuthError(AuthFailure.network);
    } on PostgrestException {
      throw const AuthError(AuthFailure.unknown);
    }
  }
}
