import '../../domain/entities/water_reminder.dart';

/// Textes de l'hydratation. On encourage à boire un peu, régulièrement :
/// jamais « buvez N verres maintenant », jamais de reproche.
abstract final class WaterTexts {
  /// « 1 verre », « 3 verres »
  static String glasses(int n) => '$n ${n > 1 ? 'verres' : 'verre'}';

  /// « 1 250 ml »
  static String ml(int ml) {
    final s = ml.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer ml';
  }

  static ({String title, String body}) reminder(WaterReminder r) =>
      switch (r.kind) {
        WaterReminderKind.nudge => (
          title: "Un petit verre d'eau ?",
          body: r.glasses == 0
              ? "Pensez à boire un verre d'eau. Objectif du jour : "
                    '${glasses(r.goal)}.'
              : 'Vous avez bu ${r.glasses} sur ${glasses(r.goal)}. '
                    'Un verre suffit pour le moment.',
        ),
        WaterReminderKind.summary when r.glasses >= r.goal => (
          title: "Objectif d'eau atteint",
          body: 'Bravo ! ${r.glasses} sur ${glasses(r.goal)} aujourd’hui.',
        ),
        WaterReminderKind.summary => (
          title: 'Votre eau aujourd’hui',
          body:
              '${r.glasses} sur ${glasses(r.goal)} : objectif non atteint. '
              'Ce n’est pas grave, on continue demain.',
        ),
      };
}
