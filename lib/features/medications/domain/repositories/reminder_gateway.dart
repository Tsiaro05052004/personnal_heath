import '../entities/medication_reminder.dart';

/// Ce dont le domaine a besoin pour rappeler les prises. Implémenté avec
/// les notifications du système (data/reminders), remplacé dans les tests.
abstract interface class ReminderGateway {
  /// Remplace les rappels « à l'heure » et « 2e rappel » planifiés par
  /// [reminders]. Les rappels « plus tard » en cours sont conservés, ainsi
  /// que ceux déjà dus à [now] mais pas encore affichés par le système.
  Future<void> replaceAll(List<MedicationReminder> reminders, DateTime now);

  /// Planifie un rappel « plus tard » (ReminderKind.snooze).
  Future<void> snooze(MedicationReminder reminder);

  /// Retire tous les rappels de cette prise, y compris celui déjà affiché.
  Future<void> cancelFor(String medicationId, DateTime scheduledAt);

  /// Autorisations accordées pour les rappels.
  Future<ReminderPermissions> permissions();

  /// Demande les autorisations manquantes (fenêtres du système).
  Future<ReminderPermissions> requestPermissions();
}

/// État des autorisations nécessaires aux rappels.
class ReminderPermissions {
  const ReminderPermissions({
    required this.notifications,
    required this.exactAlarms,
    this.supported = true,
  });

  /// L'appareil sait-il planifier des rappels ? (Non sur ordinateur.)
  final bool supported;

  /// Le système peut-il afficher les notifications de l'appli ?
  final bool notifications;

  /// Les rappels tombent-ils à l'heure exacte ? (Sinon, Android peut les
  /// décaler de quelques minutes.)
  final bool exactAlarms;

  /// Faut-il demander quelque chose à l'utilisateur ?
  bool get needsRequest => supported && !(notifications && exactAlarms);
}
