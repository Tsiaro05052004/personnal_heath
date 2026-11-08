import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';
import 'package:personnal_heath/features/medications/domain/services/medication_rules.dart';

void main() {
  Medication med({
    String name = 'Paracétamol',
    List<DoseTime> times = const [DoseTime(8, 0)],
    double quantity = 1,
    DateTime? end,
  }) => Medication(
    id: '',
    name: name,
    quantityPerIntake: quantity,
    startDate: DateTime(2026, 11, 8),
    endDate: end,
    doseTimes: times,
  );

  test('un médicament complet est valide', () {
    expect(MedicationRules.validate(med()), isEmpty);
  });

  test('détecte chaque erreur de saisie', () {
    expect(MedicationRules.validate(med(name: '  ')), {
      MedicationError.emptyName,
    });
    expect(MedicationRules.validate(med(times: [])), {
      MedicationError.noDoseTime,
    });
    expect(
      MedicationRules.validate(
        med(times: const [DoseTime(8, 0), DoseTime(8, 0)]),
      ),
      {MedicationError.duplicateDoseTime},
    );
    expect(MedicationRules.validate(med(quantity: 0)), {
      MedicationError.invalidQuantity,
    });
    expect(MedicationRules.validate(med(end: DateTime(2026, 11, 7))), {
      MedicationError.endBeforeStart,
    });
  });

  test('horaires par défaut : autant que de prises par jour', () {
    for (var n = 1; n <= MedicationRules.maxFrequency; n++) {
      expect(MedicationRules.defaultTimes(n), hasLength(n));
    }
    expect(MedicationRules.defaultTimes(3).map((t) => t.toString()), [
      '08:00',
      '14:00',
      '20:00',
    ]);
  });
}
