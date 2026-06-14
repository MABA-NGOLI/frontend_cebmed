import 'package:flutter/material.dart';

import 'package:frontend_cebmed/services/api_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool codeSent = false;
  String? errorMessage;
  String? successMessage;

  bool get canRequestCode =>
      emailController.text.trim().isNotEmpty && !isLoading;

  bool get canResetPassword =>
      emailController.text.trim().isNotEmpty &&
      codeController.text.trim().length == 5 &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      !isLoading;

  void onFieldChanged() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'\d'))) return false;
    if (!password.contains(RegExp(r'[^a-zA-Z\d]'))) return false;
    return true;
  }

  Future<bool> requestCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      errorMessage = 'Adresse e-mail invalide';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await ApiService.requestPasswordReset(email: email);
      codeSent = true;
      successMessage = 'Code envoyé si le compte existe';
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (!_isStrongPassword(password)) {
      errorMessage =
          'Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      errorMessage = 'Les mots de passe ne correspondent pas';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await ApiService.resetPassword(
        email: email,
        code: code,
        newPassword: password,
      );
      successMessage = 'Mot de passe modifié';
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
