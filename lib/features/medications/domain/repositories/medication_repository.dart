import '../entities/intake_log.dart';
import '../entities/medication.dart';

/// Contrat d'accès aux médicaments et aux prises. L'implémentation (data/)
/// écrit d'abord en local, hors ligne.
abstract interface class MedicationRepository {
  /// Médicaments non supprimés, mis à jour à chaque modification.
  /// [includeDeleted] : aussi les supprimés (avec [Medication.deletedAt]),
  /// pour l'historique.
  Stream<List<Medication>> watchMedications({bool includeDeleted = false});

  Future<Medication?> getMedication(String id);

  /// Crée (si [Medication.isNew]) ou modifie un médicament et ses horaires.
  /// Renvoie l'identifiant.
  Future<String> saveMedication(Medication medication);

  /// Supprime le médicament et ses horaires (l'historique des prises reste).
  Future<void> deleteMedication(String id);

  /// Prises enregistrées dont l'heure prévue est dans [from, to[.
  Stream<List<IntakeLog>> watchIntakeLogs(DateTime from, DateTime to);

  /// Enregistre une prise ; remplace celle du même horaire si elle existe.
  Future<void> saveIntakeLog(IntakeLog log);
}
