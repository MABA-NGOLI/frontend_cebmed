import 'package:flutter/material.dart';
import 'package:frontend_cebmed/services/api_service.dart';

class SignupViewModel extends ChangeNotifier {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool acceptedPolicies = false;
  bool isLoading = false;
  String? errorMessage;

  bool get canSubmit =>
      firstNameController.text.trim().isNotEmpty &&
          lastNameController.text.trim().isNotEmpty &&
          dateOfBirthController.text.trim().isNotEmpty &&
          emailController.text.trim().isNotEmpty &&
          passwordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          acceptedPolicies &&
          !isLoading;

  void onFieldChanged() {
    if (errorMessage != null) {
      errorMessage = null;
    }
    notifyListeners();
  }

  void setAcceptedPolicies(bool value) {
    acceptedPolicies = value;
    notifyListeners();
  }

  Future<void> pickDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    final day = selected.day.toString().padLeft(2, '0');
    final month = selected.month.toString().padLeft(2, '0');

    dateOfBirthController.text = '$day/$month/${selected.year}';
    notifyListeners();
  }

  String? _toApiBirthDate() {
    final raw = dateOfBirthController.text.trim();
    final parts = raw.split('/');

    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    final date = DateTime(year, month, day);

    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'\d'))) return false;
    if (!password.contains(RegExp(r'[^a-zA-Z\d]'))) return false;
    return true;
  }

  Future<bool> signup() async {
    if (!acceptedPolicies) {
      errorMessage = 'Tu dois accepter les conditions';
      notifyListeners();
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      errorMessage = 'Les mots de passe ne correspondent pas';
      notifyListeners();
      return false;
    }

    if (!_isStrongPassword(passwordController.text)) {
      errorMessage =
      'Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial';
      notifyListeners();
      return false;
    }

    final apiBirthDate = _toApiBirthDate();

    if (apiBirthDate == null) {
      errorMessage = 'Date invalide (format JJ/MM/AAAA)';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await ApiService.register(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        dateOfBirth: apiBirthDate,
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await ApiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      return true;
    } catch (e) {
      errorMessage = 'Inscription échouée : $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dateOfBirthController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}