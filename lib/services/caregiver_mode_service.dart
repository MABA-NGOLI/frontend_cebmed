import 'package:shared_preferences/shared_preferences.dart';

class CaregiverModeService {
  static const _roleKey = 'selected_app_role';
  static const _activePatientIdKey = 'caregiver_active_patient_id';

  static Future<void> setIsCaregiver(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, value ? 'caregiver' : 'patient');
    if (!value) {
      await prefs.remove(_activePatientIdKey);
    }
  }

  static Future<bool> isCaregiver() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) == 'caregiver';
  }

  static Future<void> setActivePatientId(int? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activePatientIdKey);
      return;
    }
    await prefs.setInt(_activePatientIdKey, id);
  }

  static Future<int?> getActivePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activePatientIdKey);
  }
}
