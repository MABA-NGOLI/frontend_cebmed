import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  UserModel? user;
  String? pictureUrl;

  static const String _addressStorageKey = 'profile_address_local';

  String get firstName => user?.firstName ?? '';
  String get lastName => user?.lastName ?? '';
  String get email => user?.email ?? '';

  Future<void> initialize() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final me = await ApiService.getMe();
      user = me.user;
      phoneController.text = me.user.phone ?? '';
      pictureUrl = me.user.picture;

      final prefs = await SharedPreferences.getInstance();
      addressController.text = prefs.getString(_addressStorageKey) ?? '';
    } catch (e) {
      errorMessage = 'Impossible de charger le profil: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPictureFromUrl(String? url) async {
    pictureUrl = (url == null || url.trim().isEmpty) ? null : url.trim();
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    if (user == null) {
      errorMessage = 'Utilisateur non charge';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await ApiService.updateMe(
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        picture: pictureUrl,
      );

      user = updated.user;
      phoneController.text = updated.user.phone ?? phoneController.text;
      pictureUrl = updated.user.picture ?? pictureUrl;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_addressStorageKey, addressController.text.trim());

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Mise a jour echouee: $e';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
