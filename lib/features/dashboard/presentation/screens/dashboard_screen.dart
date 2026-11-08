import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/placeholder_body.dart';
import '../../../../core/widgets/profile_button.dart';
import '../../../../core/widgets/tab_page.dart';

/// Écran provisoire (à développer).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabPage(
        title: 'Bonjour',
        overline: Formatters.dayTitle(DateTime.now()),
        trailing: const ProfileButton(),
        children: const [
          SizedBox(height: 48),
          PlaceholderBody(
            icon: Icons.home,
            message: 'Le résumé de votre journée apparaîtra ici.',
          ),
        ],
      ),
    );
  }
}
