import 'package:flutter/material.dart';

/// Mise en page des onglets : grand titre en haut (pas de barre d'appli,
/// comme sur les maquettes), sous-titre facultatif, puis le contenu défilant.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.overline,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Petit texte au-dessus du titre (ex. la date du jour).
  final String? overline;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overline != null)
                      Text(
                        overline!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: muted,
                        ),
                      ),
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.headlineMedium),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
