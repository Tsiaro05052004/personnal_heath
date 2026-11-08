import '../entities/app_user.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_data.dart';

/// Règles de saisie communes.
abstract final class AuthRules {
  static const minPasswordLength = 8;

  static bool isEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());
}

/// Connexion : les données déjà saisies sur ce téléphone sont rattachées
/// au compte, puis sauvegardées.
class SignIn {
  const SignIn(this._auth, this._data);

  final AuthRepository _auth;
  final SessionData _data;

  Future<AppUser> call(String email, String password) async {
    final user = await _auth.signIn(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await _data.attachTo(user.id);
    return user;
  }
}

class SignUp {
  const SignUp(this._auth, this._data);

  final AuthRepository _auth;
  final SessionData _data;

  Future<AppUser> call({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (password.length < AuthRules.minPasswordLength) {
      throw const AuthError(AuthFailure.weakPassword);
    }
    if (!AuthRules.isEmail(email)) {
      throw const AuthError(AuthFailure.invalidEmail);
    }
    final user = await _auth.signUp(
      displayName: displayName.trim(),
      email: email.trim().toLowerCase(),
      password: password,
    );
    await _data.attachTo(user.id);
    return user;
  }
}

class SendPasswordResetCode {
  const SendPasswordResetCode(this._auth);

  final AuthRepository _auth;

  Future<void> call(String email) {
    if (!AuthRules.isEmail(email)) {
      throw const AuthError(AuthFailure.invalidEmail);
    }
    return _auth.sendPasswordResetCode(email.trim().toLowerCase());
  }
}

class ResetPassword {
  const ResetPassword(this._auth, this._data);

  final AuthRepository _auth;
  final SessionData _data;

  Future<AppUser> call({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (newPassword.length < AuthRules.minPasswordLength) {
      throw const AuthError(AuthFailure.weakPassword);
    }
    final user = await _auth.resetPassword(
      email: email.trim().toLowerCase(),
      code: code.trim(),
      newPassword: newPassword,
    );
    await _data.attachTo(user.id);
    return user;
  }
}

/// Résultat d'une demande de déconnexion.
enum SignOutResult {
  done,

  /// Des données n'ont pas pu être sauvegardées (hors connexion) : il faut
  /// la confirmation de l'utilisateur pour se déconnecter quand même.
  unsavedData,
}

/// Déconnexion : on sauvegarde, on ferme la session, puis on efface les
/// données du téléphone (le suivant à se connecter ne doit rien voir) et on
/// arrête les rappels. La session d'abord : encore connectée, la synchro
/// automatique pourrait re-télécharger ce qu'on vient d'effacer.
class SignOut {
  const SignOut(this._auth, this._data);

  final AuthRepository _auth;
  final SessionData _data;

  Future<SignOutResult> call({bool force = false}) async {
    if (!force && !await _data.syncNow()) return SignOutResult.unsavedData;
    await _auth.signOut();
    await _data.clear();
    return SignOutResult.done;
  }
}

/// Suppression du compte et de TOUTES les données, sur le serveur et sur
/// le téléphone (cahier des charges 6.3).
class DeleteAccount {
  const DeleteAccount(this._auth, this._data);

  final AuthRepository _auth;
  final SessionData _data;

  Future<void> call() async {
    await _auth.deleteAccount();
    await _auth.signOut();
    await _data.clear();
  }
}
