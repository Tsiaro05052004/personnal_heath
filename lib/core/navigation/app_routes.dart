/// Chemins des pages, pour éviter les chaînes en dur dans les écrans.
///
/// Placé dans core/ (et non dans app/router.dart) pour que les widgets
/// partagés et les écrans puissent naviguer sans dépendre de app/ :
/// app/ assemble l'application, rien ne doit dépendre de lui.
abstract final class AppRoutes {
  // Onglets de la barre du bas.
  static const dashboard = '/';
  static const medications = '/medicaments';
  static const hydration = '/hydratation';
  static const hospitals = '/hopitaux';
  static const history = '/historique';

  // Compte (accessibles sans être connecté).
  static const login = '/connexion';
  static const register = '/inscription';
  static const passwordReset = '/mot-de-passe-oublie';
  static const authPages = {login, register, passwordReset};

  // Pages plein écran (sans barre du bas).
  static const settings = '/parametres';
  static const waterGoal = '/eau/objectif';
  static const newMedication = '/medicament/nouveau';
  static const medicationPattern = '/medicament/:id';
  static String editMedication(String id) => '/medicament/$id';

  /// Écran d'alarme d'une prise (ouvert depuis une notification).
  /// [action] = [takenAction] si l'utilisateur a touché « J'ai pris ».
  static const intakeAlarm = '/alarme';
  static const takenAction = 'pris';
  static String intakeAlarmFor(
    String medicationId,
    DateTime scheduledAt, {
    String? action,
  }) => Uri(
    path: intakeAlarm,
    queryParameters: {
      'med': medicationId,
      'at': '${scheduledAt.millisecondsSinceEpoch}',
      'action': ?action,
    },
  ).toString();
}
