import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/settings_action.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydratation'),
        actions: const [SettingsAction()],
      ),
      body: const PlaceholderBody(
        icon: Icons.water_drop,
        message: 'Votre compteur de verres d\'eau apparaîtra ici.',
      ),
    );
  }
}
