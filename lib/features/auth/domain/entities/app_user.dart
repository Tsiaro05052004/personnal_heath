/// L'utilisateur connecté.
class AppUser {
  const AppUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;

  /// Prénom affiché sur l'Accueil (« Bonjour, Hery »).
  final String? displayName;
}
