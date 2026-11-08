import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/tab_page.dart';

/// Écran provisoire (à développer).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabPage(
        title: 'Historique',
        children: const [
          SizedBox(height: 48),
          PlaceholderBody(
            icon: Icons.calendar_today,
            message: 'Le bilan des jours précédents apparaîtra ici.',
          ),
        ],
      ),
    );
  }
}
