import 'package:flutter/material.dart';

import '../services/api_service.dart';

class CaregiverLinkViewModel extends ChangeNotifier {
  final TextEditingController codeController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  bool get canSubmit => codeController.text.trim().isNotEmpty && !isLoading;

  void onFieldChanged() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  Future<bool> redeem() async {
    final code = codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      errorMessage = 'Code de partage obligatoire';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await ApiService.redeemCaregiverInvite(code);
      return true;
    } catch (e) {
      final raw = _cleanErrorMessage(e).trim();
      errorMessage = raw.isEmpty ? 'Code invalide ou expiré' : raw;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}

String _cleanErrorMessage(Object error) {
  return error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceAll('dÃ©jÃ ', 'déjà')
      .replaceAll('utilisÃ©e', 'utilisée')
      .replaceAll('expirÃ©', 'expiré')
      .replaceAll('rÃ©ponse', 'réponse')
      .replaceAll('crÃ©ation', 'création')
      .replaceAll('Ã©', 'é')
      .replaceAll('Ã¨', 'è')
      .replaceAll('Ã ', 'à')
      .replaceAll('Ãª', 'ê')
      .trim();
}
