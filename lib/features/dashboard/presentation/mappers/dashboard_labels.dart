import 'package:flutter/material.dart';

import '../../../../core/widgets/status_badge.dart';
import '../../../medications/domain/entities/scheduled_intake.dart';

/// Libellés de l'Accueil.
abstract final class DashboardLabels {
  /// « 10 min », « 1 h », « 2 h 15 »
  static String duration(Duration d) {
    final minutes = d.inMinutes.abs();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
  }

  /// En-tête de la carte « Prochaine prise ».
  static String nextIntakeHeader(ScheduledIntake intake, DateTime now) {
    final diff = intake.scheduledAt.difference(now);
    if (intake.state == IntakeState.pending) {
      return diff.inMinutes.abs() < 1
          ? "Prochaine prise · c'est l'heure"
          : 'Prochaine prise · en attente depuis ${duration(diff)}';
    }
    return diff.inMinutes < 1
        ? "Prochaine prise · c'est l'heure"
        : 'Prochaine prise · dans ${duration(diff)}';
  }

  /// Badge d'un groupe de prises (liste « Aujourd'hui »).
  static (String, BadgeTone, IconData?) groupBadge(IntakeState state) =>
      switch (state) {
        IntakeState.taken => ('Pris', BadgeTone.success, Icons.check),
        IntakeState.pending => (
          'En attente',
          BadgeTone.warning,
          Icons.schedule,
        ),
        IntakeState.unconfirmed => (
          'Non confirmée',
          BadgeTone.warning,
          Icons.schedule,
        ),
        IntakeState.missed => ('Non pris', BadgeTone.danger, Icons.close),
        IntakeState.upcoming => ('À venir', BadgeTone.neutral, null),
      };
}
