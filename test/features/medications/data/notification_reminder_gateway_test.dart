import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/medications/data/reminders/notification_reminder_gateway.dart';
import 'package:personnal_heath/features/medications/data/reminders/reminder_payload.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication_reminder.dart';

import '../../../helpers/fake_notification_service.dart';

void main() {
  late FakeNotificationService system;
  late NotificationReminderGateway gateway;

  setUp(() {
    system = FakeNotificationService();
    gateway = NotificationReminderGateway(
      system,
      (r) => (title: 'Rappel ${r.medication.name}', body: r.kind.name),
    );
  });

  /// « Maintenant » : 8 novembre, 12h00.
  final now = DateTime(2026, 11, 8, 12);
  Future<void> replace(List<MedicationReminder> r, {DateTime? at}) =>
      gateway.replaceAll(r, at ?? now);

  Medication para([String name = 'Paracétamol']) => Medication(
    id: 'para',
    name: name,
    startDate: DateTime(2026, 11, 1),
    doseTimes: const [DoseTime(20, 0)],
  );

  MedicationReminder reminder(
    ReminderKind kind, {
    int hour = 20,
    Medication? medication,
  }) => MedicationReminder(
    kind: kind,
    medication: medication ?? para(),
    scheduledAt: DateTime(2026, 11, 8, hour),
    fireAt: DateTime(2026, 11, 8, hour, kind == ReminderKind.dose ? 0 : 30),
  );

  test('planifie les rappels avec de quoi retrouver la prise', () async {
    await replace([
      reminder(ReminderKind.dose),
      reminder(ReminderKind.followUp),
    ]);

    expect(system.byTime.map((n) => n.at), [
      DateTime(2026, 11, 8, 20),
      DateTime(2026, 11, 8, 20, 30),
    ]);
    final payload = ReminderPayload.decode(system.byTime.first.payload)!;
    expect(payload.medicationId, 'para');
    expect(payload.scheduledAt, DateTime(2026, 11, 8, 20));
    expect(system.byTime.first.fullScreen, isTrue);
  });

  test('ne replanifie pas ce qui est déjà planifié à l’identique', () async {
    final reminders = [reminder(ReminderKind.dose)];
    await replace(reminders);
    await replace(reminders);

    expect(system.scheduleCalls, 1);
  });

  test('replanifie si le texte change (médicament renommé)', () async {
    await replace([reminder(ReminderKind.dose)]);
    await replace([reminder(ReminderKind.dose, medication: para('Doliprane'))]);

    expect(system.scheduleCalls, 2);
    expect(system.byTime.single.title, 'Rappel Doliprane');
  });

  test(
    'retire les rappels qui ne sont plus voulus, garde « plus tard »',
    () async {
      await replace([reminder(ReminderKind.dose, hour: 14)]);
      await gateway.snooze(reminder(ReminderKind.snooze, hour: 8));

      await replace([reminder(ReminderKind.dose)]);

      expect(
        system.byTime.map((n) => ReminderPayload.decode(n.payload)!.kind),
        [ReminderKind.snooze, ReminderKind.dose],
      );
    },
  );

  test('cancelFor retire tous les rappels de la prise', () async {
    await replace([
      reminder(ReminderKind.dose),
      reminder(ReminderKind.followUp),
    ]);
    await gateway.snooze(reminder(ReminderKind.snooze));

    await gateway.cancelFor('para', DateTime(2026, 11, 8, 20));

    expect(system.scheduled, isEmpty);
  });

  test('ignore les notifications qui ne sont pas des prises', () {
    expect(ReminderPayload.decode('{"type":"eau"}'), isNull);
    expect(ReminderPayload.decode('pas du json'), isNull);
    expect(ReminderPayload.decode(null), isNull);
  });
  test('un rappel déjà dû mais pas encore affiché n’est pas annulé', () async {
    // Bogue vu sur le Realme : le rappel de 12h35, retardé par le
    // système, était annulé en rouvrant l'appli à 12h35:15.
    await replace([reminder(ReminderKind.dose)]);
    final due = system.byTime.single;

    await replace(const [], at: DateTime(2026, 11, 8, 20, 0, 15));

    expect(system.scheduled.values, [due]);
  });

  test('un rappel futur qui n’est plus voulu est annulé', () async {
    await replace([reminder(ReminderKind.dose)]);
    await replace(const []);
    expect(system.scheduled, isEmpty);
  });
}
