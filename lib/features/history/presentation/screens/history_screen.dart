import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/settings_action.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: const [SettingsAction()],
      ),
      body: const PlaceholderBody(
        icon: Icons.history,
        message: 'Le bilan des jours précédents apparaîtra ici.',
      ),
    );
  }
}
