import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/signup_view_model.dart';
import '../../widgets/auth/auth_widgets.dart';
import 'email_verify_view.dart';
import 'legal_document_view.dart';

class SignupView extends StatefulWidget {
  const SignupView({
    super.key,
    required this.onBack,
    required this.onSuccess,
    required this.onGoLogin,
  });

  final VoidCallback onBack;
  final VoidCallback onSuccess;
  final VoidCallback onGoLogin;

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  late final SignupViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SignupViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _viewModel.signup();
    if (!mounted) return;
    if (ok) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerifyView(email: _viewModel.emailController.text.trim()),
        ),
      );
      if (mounted) widget.onGoLogin();
    }
  }

  void _openLegal({required String title, required String assetPath}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentView(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
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
                        child: Text('Creer votre compte', style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Commence ton suivi sante en quelques etapes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              controller: _viewModel.lastNameController,
                              hint: 'Nom',
                              onChanged: (_) => _viewModel.onFieldChanged(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AuthTextField(
                              controller: _viewModel.firstNameController,
                              hint: 'Prenom',
                              onChanged: (_) => _viewModel.onFieldChanged(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AuthTextField(
                        controller: _viewModel.dateOfBirthController,
                        hint: 'Date de naissance',
                        readOnly: true,
                        onTap: () => _viewModel.pickDate(context),
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 8),
                      _PasswordRules(password: _viewModel.passwordController.text),
                      const SizedBox(height: 10),
                      AuthTextField(
                        controller: _viewModel.confirmPasswordController,
                        hint: 'Confirmation',
                        obscure: true,
                        onChanged: (_) => _viewModel.onFieldChanged(),
                      ),
                      const SizedBox(height: 14),
                      PolicyCheckbox(
                        value: _viewModel.acceptedPolicies,
                        onChanged: _viewModel.setAcceptedPolicies,
                        onOpenTerms: () => _openLegal(title: 'Conditions generales d utilisation (CGU)', assetPath: 'assets/legal/cgu.pdf'),
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 6),
                        AuthErrorText(message: _viewModel.errorMessage!),
                      ],
                      const SizedBox(height: 18),
                      AuthPrimaryButton(
                        label: 'S inscrire',
                        isLoading: _viewModel.isLoading,
                        onPressed: _viewModel.canSubmit ? _submit : null,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: widget.onGoLogin,
                          child: const Text('Deja un compte ? Connexion'),
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

class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rule(label: '8 caractères minimum', ok: password.length >= 8),
        _Rule(label: 'Une majuscule', ok: password.contains(RegExp(r'[A-Z]'))),
        _Rule(label: 'Une minuscule', ok: password.contains(RegExp(r'[a-z]'))),
        _Rule(label: 'Un chiffre', ok: password.contains(RegExp(r'\d'))),
        _Rule(label: 'Un caractère spécial', ok: password.contains(RegExp(r'[^a-zA-Z\d]'))),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: ok ? Colors.green : Colors.black38,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ok ? Colors.green : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

