import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';
import 'validators.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/form_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .signUp(_name.text, _email.text, _password.text);
  }

  void _openLogin() {
    ref.read(authControllerProvider.notifier).clearError();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return AuthScaffold(
      onBack: _openLogin,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormHeading(
                    title: 'Create account',
                    subtitle: 'Join and start earning Points.',
                  ),
                  const SizedBox(height: 20),
                  if (auth.errorMessage != null) ...[
                    ErrorBanner(auth.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PasswordField(
                    key: const Key('password'),
                    controller: _password,
                    label: 'Password',
                    autofillHint: AutofillHints.newPassword,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 14),
                  PasswordField(
                    key: const Key('confirm'),
                    controller: _confirm,
                    label: 'Confirm password',
                    autofillHint: AutofillHints.newPassword,
                    validator: (value) =>
                        Validators.confirmPassword(value, _password.text),
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Create account',
                    loading: auth.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: auth.isLoading ? null : _openLogin,
                        child: const Text('Log in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
