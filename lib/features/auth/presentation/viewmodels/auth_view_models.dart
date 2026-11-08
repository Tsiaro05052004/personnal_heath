import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/auth_providers.dart';
import '../../domain/entities/auth_failure.dart';

/// État commun des formulaires de compte.
class AuthFormState {
  const AuthFormState({this.busy = false, this.error, this.codeSent = false});

  final bool busy;
  final AuthFailure? error;

  /// Mot de passe oublié : le code a été envoyé par e-mail.
  final bool codeSent;

  AuthFormState copyWith({
    bool? busy,
    AuthFailure? Function()? error,
    bool? codeSent,
  }) => AuthFormState(
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
    codeSent: codeSent ?? this.codeSent,
  );
}

/// Base des ViewModels de compte : occupe le bouton, traduit les erreurs.
abstract class _AuthFormViewModel extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  /// Renvoie true si l'action a réussi.
  Future<bool> run(Future<void> Function() action) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, error: () => null);
    // Après une connexion réussie, le routeur quitte l'écran et ce
    // ViewModel est détruit avant la fin de l'action : on vérifie qu'il
    // est encore là avant de toucher à son état.
    try {
      await action();
      if (ref.mounted) state = state.copyWith(busy: false);
      return true;
    } on AuthError catch (e) {
      if (ref.mounted) {
        state = state.copyWith(busy: false, error: () => e.failure);
      }
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(busy: false, error: () => AuthFailure.unknown);
      }
      return false;
    }
  }
}

final loginViewModelProvider =
    NotifierProvider.autoDispose<LoginViewModel, AuthFormState>(
      LoginViewModel.new,
    );

class LoginViewModel extends _AuthFormViewModel {
  Future<bool> signIn(String email, String password) =>
      run(() => ref.read(signInProvider)(email, password));
}

final registerViewModelProvider =
    NotifierProvider.autoDispose<RegisterViewModel, AuthFormState>(
      RegisterViewModel.new,
    );

class RegisterViewModel extends _AuthFormViewModel {
  Future<bool> signUp({
    required String displayName,
    required String email,
    required String password,
  }) => run(
    () => ref.read(signUpProvider)(
      displayName: displayName,
      email: email,
      password: password,
    ),
  );
}

final passwordResetViewModelProvider =
    NotifierProvider.autoDispose<PasswordResetViewModel, AuthFormState>(
      PasswordResetViewModel.new,
    );

class PasswordResetViewModel extends _AuthFormViewModel {
  Future<bool> sendCode(String email) async {
    final ok = await run(() => ref.read(sendPasswordResetCodeProvider)(email));
    if (ok && ref.mounted) state = state.copyWith(codeSent: true);
    return ok;
  }

  Future<bool> reset({
    required String email,
    required String code,
    required String newPassword,
  }) => run(
    () => ref.read(resetPasswordProvider)(
      email: email,
      code: code,
      newPassword: newPassword,
    ),
  );

  void changeEmail() => state = const AuthFormState();
}
