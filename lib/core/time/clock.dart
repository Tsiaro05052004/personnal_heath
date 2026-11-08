import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Heure actuelle, rafraîchie chaque minute : les statuts « en attente » /
/// « non confirmée » changent avec le temps, l'écran doit suivre.
///
/// Toujours lire l'heure par ce provider (jamais `DateTime.now()` dans un
/// ViewModel) : les tests le remplacent par une heure fixe.
final clockProvider = NotifierProvider<Clock, DateTime>(Clock.new);

class Clock extends Notifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refresh(),
    );
    ref.onDispose(timer.cancel);
    return _currentMinute();
  }

  void _refresh() {
    final now = _currentMinute();
    if (now != state) state = now;
  }

  static DateTime _currentMinute() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }
}

/// Horloge figée, pour les tests.
class FixedClock extends Clock {
  FixedClock(this.now);

  final DateTime now;

  @override
  DateTime build() => now;
}
