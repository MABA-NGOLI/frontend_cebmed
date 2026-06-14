import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/forgot_password_view_model.dart';
import '../../widgets/auth/auth_widgets.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  final VoidCallback onBack;
  final VoidCallback onSuccess;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final ForgotPasswordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ForgotPasswordViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    await _viewModel.requestCode();
  }

  Future<void> _resetPassword() async {
    final ok = await _viewModel.resetPassword();
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifié')),
    );
    widget.onSuccess();
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
                        child: Text(
                          'Mot de passe oublié',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _viewModel.codeSent
                              ? 'Entre le code reçu par e-mail'
                              : 'Réinitialise ton accès CEBMED',
                          textAlign: TextAlign.center,
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
                        readOnly: _viewModel.codeSent,
                        onChanged: (_) => _viewModel.onFieldChanged(),
                      ),
                      if (_viewModel.codeSent) ...[
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _viewModel.codeController,
                          hint: 'Code reçu par e-mail',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _viewModel.onFieldChanged(),
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _viewModel.passwordController,
                          hint: 'Nouveau mot de passe',
                          obscure: true,
                          onChanged: (_) => _viewModel.onFieldChanged(),
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _viewModel.confirmPasswordController,
                          hint: 'Confirmer le mot de passe',
                          obscure: true,
                          onChanged: (_) => _viewModel.onFieldChanged(),
                        ),
                      ],
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        AuthErrorText(message: _viewModel.errorMessage!),
                      ],
                      if (_viewModel.successMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _viewModel.successMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                              ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: _viewModel.codeSent
                            ? 'Modifier le mot de passe'
                            : 'Recevoir un code',
                        isLoading: _viewModel.isLoading,
                        onPressed: _viewModel.codeSent
                            ? (_viewModel.canResetPassword ? _resetPassword : null)
                            : (_viewModel.canRequestCode ? _requestCode : null),
                      ),
                      if (_viewModel.codeSent) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: _viewModel.isLoading ? null : _requestCode,
                            child: const Text('Renvoyer le code'),
                          ),
                        ),
                      ],
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
