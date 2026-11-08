import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../mappers/auth_failure_label.dart';
import '../viewmodels/auth_view_models.dart';
import '../widgets/auth_widgets.dart';

/// Connexion (maquette 1). Une fois connecté, le routeur ouvre l'Accueil.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(loginViewModelProvider.notifier)
        .signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            children: [
              const Align(alignment: Alignment.centerLeft, child: AppLogo()),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text('Ma Santé', style: text.headlineMedium),
              ),
              const SizedBox(height: 8),
              Text(
                'Vos médicaments, votre eau et les hôpitaux proches, au même '
                'endroit.',
                style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              LabeledField(
                label: 'Adresse e-mail',
                controller: _email,
                hint: 'exemple@mail.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: _password,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.passwordReset),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              AuthErrorText(state.error?.label),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.busy ? null : _submit,
                child: state.busy
                    ? const SizedBox.square(
                        dimension: 26,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Text('Se connecter'),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.register),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                ),
                child: const Text('Créer un compte'),
              ),
              const SizedBox(height: 40),
              const PrivacyNote(),
            ],
          ),
        ),
      ),
    );
  }
}
