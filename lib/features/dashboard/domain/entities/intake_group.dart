import '../../../medications/domain/entities/scheduled_intake.dart';

/// Les prises prévues à la même heure (« 20h00 · Paracétamol,
/// Amoxicilline »), avec un état commun.
class IntakeGroup {
  const IntakeGroup({
    required this.at,
    required this.intakes,
    required this.state,
  });

  final DateTime at;
  final List<ScheduledIntake> intakes;
  final IntakeState state;

  List<String> get medicationNames => [
    for (final i in intakes) i.medication.name,
  ];
}
