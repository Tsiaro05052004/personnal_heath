import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: const PlaceholderBody(
        icon: Icons.settings,
        message: 'Vos réglages apparaîtront ici.',
      ),
    );
  }
}
