import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/tab_page.dart';

/// Écran provisoire (à développer).
class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabPage(
        title: 'Mon eau du jour',
        children: const [
          SizedBox(height: 48),
          PlaceholderBody(
            icon: Icons.water_drop,
            message: "Votre compteur de verres d'eau apparaîtra ici.",
          ),
        ],
      ),
    );
  }
}
