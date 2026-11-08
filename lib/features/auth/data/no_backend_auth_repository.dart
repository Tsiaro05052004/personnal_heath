import '../domain/entities/app_user.dart';
import '../domain/entities/auth_failure.dart';
import '../domain/repositories/auth_repository.dart';

/// Appli lancée sans configuration Supabase (tests, ordinateur) : pas de
/// compte, tout reste sur l'appareil.
class NoBackendAuthRepository implements AuthRepository {
  const NoBackendAuthRepository();

  static Never _unavailable() => throw const AuthError(AuthFailure.network);

  @override
  AppUser? get currentUser => null;
  @override
  Stream<AppUser?> watchUser() => const Stream.empty();
  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _unavailable();
  @override
  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) => _unavailable();
  @override
  Future<void> sendPasswordResetCode(String email) => _unavailable();
  @override
  Future<AppUser> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _unavailable();
  @override
  Future<void> deleteAccount() => _unavailable();
  @override
  Future<void> signOut() async {}
}
