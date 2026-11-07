import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/settings_action.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes médicaments'),
        actions: const [SettingsAction()],
      ),
      body: const PlaceholderBody(
        icon: Icons.medication,
        message: 'Vos médicaments et vos prises apparaîtront ici.',
      ),
    );
  }
}
