import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_widgets.dart';

class EmailVerifyView extends StatefulWidget {
  const EmailVerifyView({super.key, required this.email});

  final String email;

  @override
  State<EmailVerifyView> createState() => _EmailVerifyViewState();
}

class _EmailVerifyViewState extends State<EmailVerifyView> {
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await ApiService.resendVerificationEmail(widget.email);
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Entrez le code reçu par email');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ApiService.verifyEmail(email: widget.email, code: code);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 56, color: AppTheme.primaryPink),
                  const SizedBox(height: 16),
                  Text(
                    'Vérifiez votre email',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Un code de vérification sera envoyé à\n${widget.email}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_codeSent) ...[
                    AuthTextField(
                      controller: _codeController,
                      hint: 'Code à 5 chiffres',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 24),
                    AuthPrimaryButton(
                      label: 'Vérifier',
                      isLoading: _isVerifying,
                      onPressed: _isVerifying ? null : _verify,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _isSending ? null : _sendCode,
                      child: const Text('Renvoyer le code'),
                    ),
                  ] else ...[
                    AuthPrimaryButton(
                      label: 'Envoyer le code',
                      isLoading: _isSending,
                      onPressed: _isSending ? null : _sendCode,
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    AuthErrorText(message: _errorMessage!),
                  ],
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour à la connexion'),
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
