import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mappers/auth_failure_label.dart';
import '../viewmodels/auth_view_models.dart';
import '../widgets/auth_widgets.dart';

/// Inscription : prénom, e-mail, mot de passe. Une fois inscrit, le
/// routeur ouvre l'Accueil.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(registerViewModelProvider.notifier)
        .signUp(
          displayName: _name.text,
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            LabeledField(
              label: 'Votre prénom',
              controller: _name,
              hint: 'Ex. Hery',
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
            ),
            const SizedBox(height: 20),
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
              isNew: true,
              onSubmitted: (_) => _submit(),
            ),
            AuthErrorText(state.error?.label),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.busy ? null : _submit,
              child: state.busy
                  ? const SizedBox.square(
                      dimension: 26,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Créer mon compte'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("J'ai déjà un compte"),
            ),
            const SizedBox(height: 24),
            const PrivacyNote(),
          ],
        ),
      ),
    );
  }
}
