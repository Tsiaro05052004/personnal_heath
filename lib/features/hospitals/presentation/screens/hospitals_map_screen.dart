import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/settings_action.dart';

class HospitalsMapScreen extends StatelessWidget {
  const HospitalsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte'),
        actions: const [SettingsAction()],
      ),
      body: const PlaceholderBody(
        icon: Icons.map,
        message: 'La carte des hôpitaux proches apparaîtra ici.',
      ),
    );
  }
}
