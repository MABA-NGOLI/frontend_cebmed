import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_widgets.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (code.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Tous les champs sont obligatoires');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.resetPassword(
        email: widget.email,
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé avec succès')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryPink,
      body: SafeArea(
        child: Column(
          children: [
            AuthHeader(onBack: () => Navigator.pop(context)),
            AuthContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('Nouveau mot de passe', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Entrez le code reçu par email et votre nouveau mot de passe.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: _codeController,
                    hint: 'Code à 5 chiffres',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    controller: _passwordController,
                    hint: 'Nouveau mot de passe',
                    obscure: true,
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    controller: _confirmController,
                    hint: 'Confirmer le mot de passe',
                    obscure: true,
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    AuthErrorText(message: _errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Réinitialiser',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
