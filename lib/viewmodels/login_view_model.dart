import 'package:flutter/material.dart';

import 'package:frontend_cebmed/services/api_service.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  bool get canSubmit =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      !isLoading;

  void onFieldChanged() {
    if (errorMessage != null) {
      errorMessage = null;
    }
    notifyListeners();
  }

  Future<bool> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      errorMessage = 'Email et mot de passe obligatoires';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await ApiService.login(email: email, password: password);
      return true;
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      if (raw.contains('401') || raw.contains('incorrect')) {
        errorMessage = 'Email ou mot de passe incorrect';
      } else if (raw.isEmpty) {
        errorMessage = 'Connexion impossible pour le moment';
      } else {
        errorMessage = raw;
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

