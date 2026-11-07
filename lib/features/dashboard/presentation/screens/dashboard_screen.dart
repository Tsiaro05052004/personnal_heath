import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/settings_action.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aujourd'hui"),
        actions: const [SettingsAction()],
      ),
      body: const PlaceholderBody(
        icon: Icons.home,
        message: 'Le résumé de votre journée apparaîtra ici.',
      ),
    );
  }
}
