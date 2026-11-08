/// Pourquoi une opération de compte a échoué (messages rédigés par la
/// présentation).
enum AuthFailure {
  invalidCredentials,
  emailAlreadyUsed,
  weakPassword,
  invalidEmail,
  invalidCode,
  tooManyAttempts,
  network,
  unknown,
}

class AuthError implements Exception {
  const AuthError(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthError($failure)';
}
