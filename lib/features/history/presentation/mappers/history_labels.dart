import 'package:flutter/material.dart';

import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/history_day.dart';

abstract final class HistoryLabels {
  /// « 5 / 5 prises · 1 non confirmée »
  static String intakes(HistoryDay d) {
    final notes = [
      if (d.unconfirmed > 0)
        '${d.unconfirmed} non ${d.unconfirmed > 1 ? 'confirmées' : 'confirmée'}',
      if (d.missed > 0) '${d.missed} non ${d.missed > 1 ? 'prises' : 'prise'}',
      if (d.late > 0) '${d.late} en retard',
    ];
    return [
      '${d.confirmed} / ${d.planned} ${d.planned > 1 ? 'prises' : 'prise'}',
      ...notes,
    ].join(' · ');
  }

  static (String, BadgeTone, IconData?) verdict(DayVerdict v) => switch (v) {
    DayVerdict.respected => ('Respecté', BadgeTone.success, Icons.check),
    DayVerdict.partial => ('Partiel', BadgeTone.warning, null),
  };
}
