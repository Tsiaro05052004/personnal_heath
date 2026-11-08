import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/tab_page.dart';

/// Écran provisoire (à développer).
class HospitalsMapScreen extends StatelessWidget {
  const HospitalsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabPage(
        title: 'Hôpitaux',
        children: const [
          SizedBox(height: 48),
          PlaceholderBody(
            icon: Icons.add_location_alt,
            message: 'La carte des hôpitaux proches apparaîtra ici.',
          ),
        ],
      ),
    );
  }
}
