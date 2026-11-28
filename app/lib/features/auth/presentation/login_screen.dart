import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import 'validators.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/form_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
  }

  void _openSignUp() {
    ref.read(authControllerProvider.notifier).clearError();
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return AuthScaffold(
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
                    title: 'Welcome back',
                    subtitle: 'Log in to keep moving.',
                  ),
                  const SizedBox(height: 20),
                  if (auth.errorMessage != null) ...[
                    ErrorBanner(auth.errorMessage!),
                    const SizedBox(height: 16),
                  ],
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
                    validator: Validators.password,
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Log in',
                    loading: auth.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: auth.isLoading ? null : _openSignUp,
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _DemoHint(),
      ],
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pastel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Demo account: ${FakeAuthRepository.demoEmail} / '
        '${FakeAuthRepository.demoPassword}',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.deep, fontSize: 13),
      ),
    );
  }
}
