import 'package:flutter/material.dart';

import '../models/caregiver_profile_model.dart';
import '../services/api_service.dart';
import '../services/caregiver_mode_service.dart';

class CaregiverHubViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool isSubmittingCode = false;
  String? errorMessage;

  List<CaregiverProfileModel> profiles = const [];
  CaregiverProfileModel? activeProfile;

  bool get hasProfiles => profiles.isNotEmpty;

  Future<void> initialize() async {
    await refreshProfiles();
  }

  Future<void> refreshProfiles() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final all = await ApiService.getCaregiverProfilesMine();
      profiles = all;

      final savedActiveId = await CaregiverModeService.getActivePatientId();
      activeProfile = null;
      for (final p in profiles) {
        if (p.patientId == savedActiveId) {
          activeProfile = p;
          break;
        }
      }

      activeProfile ??= profiles.isNotEmpty ? profiles.first : null;
      await CaregiverModeService.setActivePatientId(activeProfile?.patientId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectProfile(CaregiverProfileModel profile) async {
    activeProfile = profile;
    await CaregiverModeService.setActivePatientId(profile.patientId);
    notifyListeners();
  }

  Future<bool> deleteProfileRelation(CaregiverProfileModel profile) async {
    final relationId = profile.relationId;
    if (relationId == null) {
      errorMessage = 'Relation aidant introuvable';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await ApiService.deleteCaregiverRelation(relationId);
      await refreshProfiles();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> redeemNewCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      errorMessage = 'Code de partage obligatoire';
      notifyListeners();
      return false;
    }

    isSubmittingCode = true;
    errorMessage = null;
    notifyListeners();

    try {
      await ApiService.redeemCaregiverInvite(code);
      await refreshProfiles();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmittingCode = false;
      notifyListeners();
    }
  }
}
