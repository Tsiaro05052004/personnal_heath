import '../entities/app_user.dart';

/// Comptes (Supabase Auth). Lève [AuthError] en cas d'échec.
abstract interface class AuthRepository {
  /// Utilisateur connecté maintenant (session gardée sur le téléphone,
  /// disponible hors ligne).
  AppUser? get currentUser;

  /// Change à chaque connexion / déconnexion.
  Stream<AppUser?> watchUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  /// Envoie un code à 6 chiffres par e-mail pour changer de mot de passe.
  Future<void> sendPasswordResetCode(String email);

  /// Vérifie le code reçu et enregistre le nouveau mot de passe (l'utilisateur
  /// est alors connecté).
  Future<AppUser> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Supprime le compte et TOUTES ses données sur le serveur.
  Future<void> deleteAccount();

  Future<void> signOut();
}
