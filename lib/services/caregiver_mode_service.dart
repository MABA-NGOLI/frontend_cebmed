import 'package:shared_preferences/shared_preferences.dart';

// Centralise le rôle choisi localement par l'utilisateur.
// Ce service ne crée pas de relation aidant: il mémorise seulement le mode d'affichage.
class CaregiverModeService {
  static const _roleKey = 'selected_app_role';
  static const _activePatientIdKey = 'caregiver_active_patient_id';

  // Passe l'application en mode patient ou aidant.
  // Quand on revient en mode patient, on retire le patient actif pour éviter
  // d'envoyer un ancien x-patient-id dans les prochaines requêtes.
  static Future<void> setIsCaregiver(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, value ? 'caregiver' : 'patient');
    if (!value) {
      await prefs.remove(_activePatientIdKey);
    }
  }

  // Permet à MainShell et ApiService de savoir si l'utilisateur navigue comme aidant.
  static Future<bool> isCaregiver() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) == 'caregiver';
  }

  // Mémorise le patient actuellement consulté par l'aidant.
  // Cet id est ensuite envoyé au backend par ApiService.careHeaders().
  static Future<void> setActivePatientId(int? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activePatientIdKey);
      return;
    }
    await prefs.setInt(_activePatientIdKey, id);
  }

  // Retourne le patient actif, ou null si aucun patient n'a été sélectionné.
  static Future<int?> getActivePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activePatientIdKey);
  }
}
