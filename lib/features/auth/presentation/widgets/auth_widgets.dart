import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form_widgets.dart';

/// Logo « Ma Santé » (cœur et croix, maquette 1).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.favorite_border, color: Colors.white, size: 52),
        Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ],
    ),
  );
}

/// Champ avec son libellé au-dessus (maquette 1).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        onSubmitted: onSubmitted,
        autocorrect: false,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}

/// Mot de passe avec l'œil pour l'afficher (utile à tout âge).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Mot de passe',
    this.isNew = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;

  /// Nouveau mot de passe (inscription) : aide « au moins 8 caractères ».
  final bool isNew;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TextField(
        controller: widget.controller,
        obscureText: !_visible,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: [
          widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
        ],
        onSubmitted: widget.onSubmitted,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.isNew ? 'Au moins 8 caractères' : null,
          suffixIcon: IconButton(
            icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
            tooltip: _visible
                ? 'Cacher le mot de passe'
                : 'Afficher le mot de passe',
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
      ),
    ],
  );
}

/// Message d'erreur sous un formulaire (ou rien).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) =>
      message == null ? const SizedBox.shrink() : FormError(message!);
}

/// « Vos informations de santé sont privées… » (maquette 1).
class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.lock_outline, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          'Vos informations de santé sont privées : vous seul pouvez les '
          'consulter.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textMuted),
        ),
      ),
    ],
  );
}
