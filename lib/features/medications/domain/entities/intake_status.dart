/// Statut ENREGISTRÉ d'une prise (un IntakeLog n'existe que si
/// l'utilisateur a agi). Une prise sans enregistrement est « non confirmée »,
/// jamais « oubliée » automatiquement.
enum IntakeStatus {
  /// L'utilisateur a confirmé la prise (l'heure réelle est conservée).
  taken,

  /// L'utilisateur a lui-même déclaré la prise oubliée.
  missed,
}
