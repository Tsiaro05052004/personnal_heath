import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../mappers/auth_failure_label.dart';
import '../viewmodels/auth_view_models.dart';
import '../widgets/auth_widgets.dart';

/// Mot de passe oublié : 1. l'e-mail reçoit un code à 6 chiffres ;
/// 2. on saisit le code et le nouveau mot de passe (pas de lien à ouvrir,
/// plus simple sur téléphone). Une fois fait, le routeur ouvre l'Accueil.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  PasswordResetViewModel get _vm =>
      ref.read(passwordResetViewModelProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetViewModelProvider);
    final text = Theme.of(context).textTheme;
    final busyIndicator = const SizedBox.square(
      dimension: 26,
      child: CircularProgressIndicator(strokeWidth: 3),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          if (!state.codeSent) ...[
            Text(
              'Saisissez votre adresse e-mail : vous recevrez un code à '
              '6 chiffres pour choisir un nouveau mot de passe.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 20),
            LabeledField(
              label: 'Adresse e-mail',
              controller: _email,
              hint: 'exemple@mail.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _vm.sendCode(_email.text),
            ),
            AuthErrorText(state.error?.label),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.busy ? null : () => _vm.sendCode(_email.text),
              child: state.busy
                  ? busyIndicator
                  : const Text('Recevoir le code'),
            ),
          ] else ...[
            Text(
              'Un code a été envoyé à ${_email.text.trim()}. Il peut mettre '
              'quelques minutes à arriver (regardez aussi les courriers '
              'indésirables).',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 20),
            LabeledField(
              label: 'Code reçu par e-mail',
              controller: _code,
              hint: '123456',
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
            ),
            const SizedBox(height: 20),
            PasswordField(
              controller: _password,
              label: 'Nouveau mot de passe',
              isNew: true,
            ),
            AuthErrorText(state.error?.label),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.busy
                  ? null
                  : () => _vm.reset(
                      email: _email.text,
                      code: _code.text,
                      newPassword: _password.text,
                    ),
              child: state.busy
                  ? busyIndicator
                  : const Text('Changer mon mot de passe'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _vm.changeEmail,
              child: const Text('Changer d’adresse ou renvoyer le code'),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Besoin d’aide ? Demandez à un proche de vous accompagner.',
            style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
