import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool notificationsEnabled = false;
  String? errorMessage;

  UserModel? user;
  String? pictureUrl;
  String? localPicturePath;

  final ImagePicker _imagePicker = ImagePicker();

  static const String _addressStorageKey = 'profile_address_local';
  static const String _picturePathStorageKey = 'profile_picture_path_local';
  static const String _notificationsStorageKey = 'notifications_enabled';

  String get firstName => user?.firstName ?? '';
  String get lastName => user?.lastName ?? '';
  String get email => user?.email ?? '';
  String get createdSinceLabel {
    final createdAt = user?.createdAt;
    if (createdAt == null) return 'Utilisateur';
    return 'Utilisateur depuis ${DateFormat('dd/MM/yyyy').format(createdAt)}';
  }

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
      localPicturePath = prefs.getString(_picturePathStorageKey);
      notificationsEnabled = prefs.getBool(_notificationsStorageKey) ?? false;
    } catch (e) {
      errorMessage = 'Impossible de charger le profil: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final granted = await NotificationService.requestPermission();
      notificationsEnabled = granted;
      await prefs.setBool(_notificationsStorageKey, granted);
      if (!granted) {
        errorMessage = 'Autorisation des notifications refusee';
      } else {
        errorMessage = null;
      }
      notifyListeners();
      return granted;
    }

    notificationsEnabled = false;
    await prefs.setBool(_notificationsStorageKey, false);
    errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<void> pickPictureFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    localPicturePath = picked.path;
    pictureUrl = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_picturePathStorageKey, picked.path);
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
      final pictureForApi = (pictureUrl != null && pictureUrl!.startsWith('http'))
          ? pictureUrl
          : null;

      final updated = await ApiService.updateMe(
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        picture: pictureForApi,
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

  Future<bool> updateIdentity({
    required String firstName,
    required String lastName,
  }) async {
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
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      );
      user = updated.user;
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

