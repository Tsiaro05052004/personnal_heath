/// Les données de santé du téléphone, vues depuis le compte : les
/// rattacher à l'utilisateur, les sauvegarder, les effacer à la
/// déconnexion (téléphone partagé : le suivant ne doit rien voir).
abstract interface class SessionData {
  /// Rattache au compte [userId] les données saisies sur ce téléphone et
  /// lance une synchronisation (sans lever d'erreur hors connexion).
  Future<void> attachTo(String userId);

  /// Envoie ce qui reste à sauvegarder. Renvoie false si des données n'ont
  /// pas pu partir (hors connexion…).
  Future<bool> syncNow();

  /// Efface toutes les données de santé du téléphone et arrête les rappels.
  Future<void> clear();
}
