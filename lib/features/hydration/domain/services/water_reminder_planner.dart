import 'dart:math' as math;

import '../entities/water_reminder.dart';
import '../entities/water_settings.dart';

/// Une heure de rappel et le nombre de verres attendu à cette heure-là.
class WaterCheckpoint {
  const WaterCheckpoint(this.at, this.target);

  final DateTime at;

  /// Objectif intermédiaire : verres qu'on espère avoir bus à [at].
  final int target;
}

/// Règles des rappels d'eau (cahier des charges, 2.3 C) : encourager à
/// boire régulièrement, jamais beaucoup d'un coup.
abstract final class WaterReminderPlanner {
  /// Au plus ce nombre de rappels par jour, même pour un grand objectif.
  static const maxNudgesPerDay = 8;

  /// Le bilan arrive ce délai avant l'heure du coucher.
  static const summaryBeforeSleep = Duration(minutes: 30);

  /// Rappels confiés au système pour ces jours (aujourd'hui compris).
  static const days = 7;

  /// Points de passage du jour [day] : répartis régulièrement entre réveil
  /// et coucher, arrondis au quart d'heure. Pour 5 verres de 7h à 22h :
  /// 9h30 (1), 12h00 (2), 14h30 (3), 17h00 (4), 19h30 (5).
  static List<WaterCheckpoint> checkpoints(WaterSettings s, DateTime day) {
    final count = math.min(s.goalGlasses, maxNudgesPerDay);
    final span = s.sleepMinute - s.wakeMinute;
    return [
      for (var i = 1; i <= count; i++)
        WaterCheckpoint(
          _at(day, _roundToQuarter(s.wakeMinute + span * i / (count + 1))),
          (s.goalGlasses * i / count).ceil(),
        ),
    ];
  }

  /// Rappels à venir après [now]. [glassesToday] = verres déjà bus
  /// aujourd'hui : un rappel dont l'objectif intermédiaire est atteint
  /// n'est pas planifié (d'où la replanification à chaque verre).
  static List<WaterReminder> plan({
    required WaterSettings settings,
    required int glassesToday,
    required DateTime now,
  }) {
    if (!settings.remindersEnabled) return const [];
    final today = DateTime(now.year, now.month, now.day);
    final reminders = <WaterReminder>[];
    for (var d = 0; d < days; d++) {
      final day = DateTime(today.year, today.month, today.day + d);
      final glasses = d == 0 ? glassesToday : 0;
      for (final cp in checkpoints(settings, day)) {
        if (cp.at.isAfter(now) && glasses < cp.target) {
          reminders.add(
            WaterReminder(
              kind: WaterReminderKind.nudge,
              at: cp.at,
              glasses: glasses,
              goal: settings.goalGlasses,
            ),
          );
        }
      }
      final summaryAt = _at(
        day,
        settings.sleepMinute,
      ).subtract(summaryBeforeSleep);
      if (summaryAt.isAfter(now)) {
        reminders.add(
          WaterReminder(
            kind: WaterReminderKind.summary,
            at: summaryAt,
            glasses: glasses,
            goal: settings.goalGlasses,
          ),
        );
      }
    }
    return reminders;
  }

  /// Prochain rappel « verre d'eau » d'aujourd'hui (affiché à l'écran).
  static DateTime? nextNudge({
    required WaterSettings settings,
    required int glassesToday,
    required DateTime now,
  }) {
    for (final r in plan(
      settings: settings,
      glassesToday: glassesToday,
      now: now,
    )) {
      if (r.kind == WaterReminderKind.nudge &&
          r.at.day == now.day &&
          r.at.month == now.month) {
        return r.at;
      }
    }
    return null;
  }

  static int _roundToQuarter(double minute) => (minute / 15).round() * 15;

  static DateTime _at(DateTime day, int minute) =>
      DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);
}
