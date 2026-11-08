import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Une notification à planifier. Générique : les features (médicaments,
/// eau) construisent le contenu, ce service ne connaît que le système.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
    this.channel = NotificationChannel.medication,
    this.actions = const [],
    this.fullScreen = false,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// Texte libre rendu à l'appli quand l'utilisateur touche la notification.
  final String payload;
  final NotificationChannel channel;
  final List<NotificationButton> actions;

  /// Afficher l'écran d'alarme plein écran, même téléphone verrouillé.
  final bool fullScreen;
}

/// Bouton sous une notification (« J'ai pris mon médicament »).
class NotificationButton {
  const NotificationButton(this.id, this.label);

  final String id;
  final String label;
}

/// Canaux Android : l'utilisateur peut régler le son de chacun. Le son
/// d'un canal ne peut plus changer après sa création : un son différent
/// demande un autre canal.
enum NotificationChannel {
  /// Son de notification ordinaire, joué une fois.
  medication('rappels_medicaments', 'Rappels de médicaments'),

  /// Sonnerie de réveil, au volume du réveil, répétée jusqu'à ce que
  /// l'utilisateur réagisse (5 min au plus).
  medicationAlarm(
    'alarme_medicaments',
    'Alarme des médicaments',
    alarmSound: true,
  ),
  water('rappels_eau', "Rappels d'hydratation");

  const NotificationChannel(this.id, this.label, {this.alarmSound = false});

  final String id;
  final String label;
  final bool alarmSound;
}

/// Durée maximale de la sonnerie d'alarme si personne ne réagit.
const alarmRingDuration = Duration(minutes: 5);

/// Une notification planifiée encore en attente dans le système.
class PendingNotification {
  const PendingNotification(this.id, this.payload);

  final int id;
  final String? payload;
}

/// L'utilisateur a touché une notification ou l'un de ses boutons.
class NotificationTap {
  const NotificationTap({required this.payload, this.actionId});

  final String payload;

  /// Bouton touché ; null si c'est la notification elle-même.
  final String? actionId;
}

/// Autorisations du système pour les notifications.
class NotificationPermissions {
  const NotificationPermissions({
    required this.notifications,
    required this.exactAlarms,
    this.supported = true,
  });

  /// False sur les plateformes sans notifications planifiées (Linux).
  final bool supported;
  final bool notifications;
  final bool exactAlarms;
}

/// Seul point d'accès aux notifications du système (architecture, §7).
abstract interface class NotificationService {
  /// Notifications touchées pendant que l'appli tourne.
  Stream<NotificationTap> get taps;

  /// Notification qui a lancé l'appli (appli fermée), le cas échéant.
  Future<NotificationTap?> launchTap();

  Future<void> schedule(ScheduledNotification notification);

  /// Annule une notification planifiée ET la retire si elle est affichée.
  Future<void> cancel(int id);

  Future<List<PendingNotification>> pending();

  Future<NotificationPermissions> permissions();

  /// Demande l'autorisation d'afficher des notifications puis, si besoin,
  /// celle des alarmes exactes (ouvre les réglages sur Android 14+).
  Future<NotificationPermissions> requestPermissions();
}

/// Remplacé au démarrage (main.dart) par le service initialisé, et dans les
/// tests par un faux service.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('NotificationService non initialisé'),
);

/// Identifiant de notification stable (31 bits) à partir d'une clé texte :
/// permet d'annuler un rappel précis sans rien stocker (FNV-1a).
int notificationIdFor(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}
