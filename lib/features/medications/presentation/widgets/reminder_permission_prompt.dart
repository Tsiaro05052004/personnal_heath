import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/medications_providers.dart';

/// Après l'ajout d'un médicament : explique pourquoi les rappels ont besoin
/// d'autorisations, puis ouvre les fenêtres du système. Ne demande rien si
/// tout est déjà accordé.
Future<void> ensureReminderPermissions(
  BuildContext context,
  WidgetRef ref,
) async {
  final gateway = ref.read(reminderGatewayProvider);
  final current = await gateway.permissions();
  if (!current.needsRequest || !context.mounted) return;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined, size: 40),
      title: const Text('Recevoir les rappels ?'),
      content: const Text(
        "Pour vous rappeler l'heure de vos médicaments, même quand "
        "l'application est fermée, votre téléphone va vous demander "
        "l'autorisation d'envoyer des notifications et des alarmes.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Autoriser'),
        ),
      ],
    ),
  );
  if (accepted != true) return;

  final result = await gateway.requestPermissions();
  // Les rappels déjà calculés doivent être confiés au système maintenant.
  await ref.read(rescheduleRemindersProvider)();
  if (!result.notifications && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sans autorisation, aucun rappel ne sera affiché. Vous pourrez '
          "l'activer dans les réglages du téléphone.",
        ),
      ),
    );
  }
}
