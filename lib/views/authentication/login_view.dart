import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/login_view_model.dart';
import '../../widgets/auth/auth_widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.onBack,
    required this.onSuccess,
    required this.onGoSignup,
    required this.onForgotPassword,
  });

  final VoidCallback onBack;
  final VoidCallback onSuccess;
  final VoidCallback onGoSignup;
  final VoidCallback onForgotPassword;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _viewModel.login();
    if (!mounted) {
      return;
    }
    if (ok) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.primaryPink,
          body: SafeArea(
            child: Column(
              children: [
                AuthHeader(onBack: widget.onBack),
                AuthContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text('Se connecter', style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Retrouve ton espace CEBMED',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        controller: _viewModel.emailController,
                        hint: 'Adresse e-mail',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => _viewModel.onFieldChanged(),
                      ),
                      const SizedBox(height: 10),
                      AuthTextField(
                        controller: _viewModel.passwordController,
                        hint: 'Mot de passe',
                        obscure: true,
                        onChanged: (_) => _viewModel.onFieldChanged(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onForgotPassword,
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        AuthErrorText(message: _viewModel.errorMessage!),
                      ],
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: 'Connexion',
                        isLoading: _viewModel.isLoading,
                        onPressed: _viewModel.canSubmit ? _submit : null,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: widget.onGoSignup,
                          child: const Text('Creer un compte'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

