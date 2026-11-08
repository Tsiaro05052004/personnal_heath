import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'sync_service.dart';

/// Décide QUAND synchroniser : peu après chaque modification locale, au
/// démarrage, au retour dans l'appli, à la connexion. Hors connexion,
/// l'échec est silencieux : on réessaiera à la prochaine occasion.
class SyncCoordinator {
  SyncCoordinator({
    required this.db,
    required this.service,
    required this.currentUserId,
    required this.onRemoteChanges,
    this.debounce = const Duration(seconds: 3),
  });

  final AppDatabase db;
  final SyncService service;
  final String? Function() currentUserId;

  /// Des données sont arrivées du serveur : replanifier les rappels.
  final Future<void> Function() onRemoteChanges;
  final Duration debounce;

  StreamSubscription<void>? _changes;
  Timer? _timer;
  Future<bool>? _running;
  bool _again = false;

  /// Écoute les modifications de la base pour synchroniser peu après.
  void start() {
    _changes ??= db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            db.medications,
            db.medicationSchedules,
            db.intakeLogs,
            db.waterSettingsTable,
            db.waterLogs,
          ]),
        )
        .listen((_) => schedule());
  }

  void schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, syncNow);
  }

  /// Synchronise maintenant. Renvoie true si tout est sauvegardé.
  Future<bool> syncNow() async {
    if (_running != null) {
      // Une synchro est en cours : on en refera une juste après.
      _again = true;
      return _running!;
    }
    final run = _run();
    _running = run;
    try {
      return await run;
    } finally {
      _running = null;
      if (_again) {
        _again = false;
        schedule();
      }
    }
  }

  /// Avant / après l'effacement de la base locale : laisse finir la synchro
  /// en cours (elle pourrait réécrire des lignes) et repart de zéro.
  Future<void> forgetProgress() async {
    _timer?.cancel();
    _again = false;
    await _running;
    await service.forgetCursors();
  }

  Future<bool> _run() async {
    final userId = currentUserId();
    if (userId == null) return false;
    try {
      final report = await service.sync(userId);
      if (report.pulled > 0) await onRemoteChanges();
      return !await service.hasUnsyncedData();
    } catch (e) {
      debugPrint('Synchronisation impossible (hors connexion ?) : $e');
      return false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _changes?.cancel();
  }
}
