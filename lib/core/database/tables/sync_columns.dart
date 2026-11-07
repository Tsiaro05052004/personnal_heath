import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Nouvel identifiant unique (UUID v4). Public car Drift recopie l'appel
/// dans le code généré.
String newId() => const Uuid().v4();

/// Colonnes communes à toutes les tables synchronisées avec le serveur.
mixin SyncColumns on Table {
  /// UUID généré sur le téléphone : la ligne a un id avant même d'être
  /// envoyée au serveur (hors ligne d'abord).
  TextColumn get id => text().clientDefault(newId)();

  /// Propriétaire ; null tant qu'aucun compte n'est connecté.
  TextColumn get userId => text().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Suppression logique, pour pouvoir propager la suppression au serveur.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// Modifiée localement et pas encore envoyée au serveur.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
