import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appointment.dart';
import '../models/auth_models.dart';
import '../models/caregiver_profile_model.dart';
import '../models/document_model.dart';
import '../models/intake_model.dart';
import '../models/stock_model.dart';
import '../models/treatment_model.dart';
import 'caregiver_mode_service.dart';

class ApiService {
  // Client HTTP injectable pour pouvoir mocker les appels API dans les tests unitaires.
  static http.Client httpClient = http.Client();

  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    // if (kIsWeb) {
    //   return 'http://localhost:3000/api';
    // }
    // if (defaultTargetPlatform == TargetPlatform.android) {
    //   return 'http://10.0.2.2:3000/api';
    // }
    // return 'http://localhost:3000/api';
    return 'http://31.207.35.91/cebmed/api';
  }

  static String? _accessToken;
  static String? _refreshToken;

  // Appelé quand la session expire pour laisser l'UI renvoyer vers la connexion.
  static VoidCallback? onSessionExpired;

  // évite de lancer plusieurs refresh token en même temps.
  static Completer<void>? _refreshCompleter;

  static const String _kAccessToken = 'auth_access_token';
  static const String _kRefreshToken = 'auth_refresh_token';

  static Future<void> _saveTokens() async {
    if (_accessToken == null || _refreshToken == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, _accessToken!);
    await prefs.setString(_kRefreshToken, _refreshToken!);
  }

  static Future<bool> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_kAccessToken);
    final refresh = prefs.getString(_kRefreshToken);
    if (access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty) {
      _accessToken = access;
      _refreshToken = refresh;
      return true;
    }
    return false;
  }

  static Map<String, String> headers() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  // Ajoute le patient actif quand l'utilisateur navigue en mode aidant.
  static Future<Map<String, String>> careHeaders() async {
    final values = Map<String, String>.from(headers());
    final isCaregiver = await CaregiverModeService.isCaregiver();
    if (!isCaregiver) return values;

    final patientId = await CaregiverModeService.getActivePatientId();
    if (patientId != null) {
      values['x-patient-id'] = patientId.toString();
    }
    return values;
  }


  static Future<http.Response> _execute(
    Future<http.Response> Function() call,
  ) async {
    final response = await call();
    if ((response.statusCode == 401 || response.statusCode == 403) &&
        _refreshToken != null) {
      await refresh();
      return call();
    }
    return response;
  }


  static dynamic _decodeJson(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<void> refresh() async {

    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return;
    }

    if (_refreshToken == null) {
      onSessionExpired?.call();
      throw Exception('Session expiré, veuillez vous reconnecter');
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      if (response.statusCode != 200) {
        await clearTokensPersisted();
        onSessionExpired?.call();
        final error = Exception('Session expiré, veuillez vous reconnecter');
        completer.completeError(error);
        throw error;
      }

      final data = _decodeJson(response) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String?;
      _refreshToken = data['refresh_token'] as String?;
      await _saveTokens();
      completer.complete();
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }


  static bool _isAccessTokenExpiredOrExpiringSoon() {
    if (_accessToken == null) return true;
    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return true;
      final padding = '=' * ((4 - parts[1].length % 4) % 4);
      final payload = utf8.decode(base64Url.decode(parts[1] + padding));
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(
        expiry.subtract(const Duration(minutes: 2)),
      );
    } catch (_) {
      return true;
    }
  }


  static Future<void> refreshIfNeeded() async {
    if (_isAccessTokenExpiredOrExpiringSoon()) {
      await refresh();
    }
  }

  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_kAccessToken);
      prefs.remove(_kRefreshToken);
    });
  }

  static Future<void> clearTokensPersisted() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }


  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers(),
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth,
        'email': email,
        'password': password,
      }),
    );

    final data = _decodeJson(response) as Map<String, dynamic>;

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception((data['message'] ?? 'Inscription impossible').toString());
    }

    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    clearTokens();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _decodeJson(response) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        (data['message'] ?? 'Email ou mot de passe incorrect').toString(),
      );
    }

    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;

    if (_accessToken == null || _accessToken!.isEmpty) {
      clearTokens();
      throw Exception('Token absent, connexion impossible');
    }

    await _saveTokens();
    return data;
  }

  static Future<void> requestPasswordReset({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password/forgot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      String message = 'Demande de réinitialisation impossible';
      try {
        final data = _decodeJson(response) as Map<String, dynamic>;
        message = (data['message'] ?? message).toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Future<void> forgotPassword(String email) async {
    await requestPasswordReset(email: email);
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Réinitialisation impossible';
      try {
        final data = _decodeJson(response) as Map<String, dynamic>;
        message = (data['message'] ?? message).toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200) {
      final data = _decodeJson(response) as Map<String, dynamic>;
      throw Exception((data['message'] ?? 'Code invalide').toString());
    }
  }

  static Future<void> resendVerificationEmail(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = _decodeJson(response) as Map<String, dynamic>;
      throw Exception(
        (data['message'] ?? 'Erreur lors de l\'envoi').toString(),
      );
    }
  }

  static Future<MeResponse> getMe() async {
    final response = await _execute(
      () => http.get(Uri.parse('$baseUrl/auth/me'), headers: headers()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur profil (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;
    if (body['user'] is Map<String, dynamic>) {
      return MeResponse.fromJson(body);
    }
    return MeResponse.fromJson({'user': body});
  }

  static Future<MeResponse> updateMe({
    String? firstName,
    String? lastName,
    String? phone,
    String? picture,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers(),
      body: jsonEncode({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (picture != null) 'picture': picture,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur mise a jour profil (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;
    if (body['user'] is Map<String, dynamic>) {
      return MeResponse.fromJson(body);
    }
    return MeResponse.fromJson({'user': body});
  }

  static Future<void> deleteMyAccount({required String password}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers(),
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Suppression impossible (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    clearTokens();
  }

  static Future<String> createCaregiverInviteCode() async {
    final response = await _execute(
      () => http.post(
        Uri.parse('$baseUrl/caregiver-invites'),
        headers: headers(),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur code de partage (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;

    final dynamic data = body['data'];
    final dynamic invite = body['invite'];

    final code =
        (body['code'] ??
                body['invite_code'] ??
                (data is Map<String, dynamic> ? data['code'] : null) ??
                (data is Map<String, dynamic> ? data['invite_code'] : null) ??
                (invite is Map<String, dynamic> ? invite['code'] : null) ??
                (invite is Map<String, dynamic> ? invite['invite_code'] : null))
            ?.toString();

    if (code == null || code.trim().isEmpty) {
      throw Exception('Code de partage absent dans la rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©ponse backend');
    }

    return code.trim();
  }

  static Future<void> redeemCaregiverInvite(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw Exception('Code de partage obligatoire');
    }

    final response = await _execute(
      () => http.post(
        Uri.parse('$baseUrl/caregiver-invites/redeem'),
        headers: headers(),
        body: jsonEncode({'code': normalized, 'invite_code': normalized}),
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Code invalide ou expiré';
      try {
        final body = _decodeJson(response) as Map<String, dynamic>;
        final raw = body['message']?.toString();
        if (raw != null && raw.trim().isNotEmpty) {
          message = raw.trim();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Future<List<CaregiverProfileModel>> getCaregiverProfilesMine() async {
    final response = await _execute(
      () => http.get(
        Uri.parse('$baseUrl/caregiver-invites/mine'),
        headers: headers(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement profils aidés (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;
    final dynamic raw = body['relations'] ?? body['data'] ?? body['invites'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CaregiverProfileModel.fromJson)
        .toList();
  }

  static Future<List<CaregiverProfileModel>> getMyPatientCaregivers() async {
    final response = await _execute(
      () => http.get(
        Uri.parse('$baseUrl/caregiver-invites/mine'),
        headers: headers(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement aidants (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;


    final dynamic raw =
        body['caregivers'] ??
        body['patient_caregivers'] ??
        body['myCaregivers'];
    if (raw is! List) return const [];

    final seen = <String>{};
    final caregivers = <CaregiverProfileModel>[];

    for (final item in raw.whereType<Map<String, dynamic>>()) {
      final caregiver = CaregiverProfileModel.fromJson(item);
      final hasName =
          caregiver.firstName.trim().isNotEmpty ||
          caregiver.lastName.trim().isNotEmpty;
      if (!hasName) continue;

      final key =
          '${caregiver.relationId ?? ''}:${caregiver.patientId ?? ''}:${caregiver.fullName}';
      if (seen.add(key)) {
        caregivers.add(caregiver);
      }
    }

    return caregivers;
  }

  static Future<void> deleteCaregiverRelation(int relationId) async {
    final response = await _execute(
      () async => http.delete(
        Uri.parse('$baseUrl/caregiver-invites/relations/$relationId'),
        headers: headers(),
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Erreur suppression relation aidant (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> updateCaregiverPermissions({
    required int relationId,
    bool? canViewAgenda,
    bool? canEditAgenda,
    bool? canViewDocuments,
    bool? canUploadDocuments,
  }) async {
    final body = <String, dynamic>{
      if (canViewAgenda != null) 'can_view_agenda': canViewAgenda,
      if (canEditAgenda != null) 'can_edit_agenda': canEditAgenda,
      if (canViewDocuments != null) 'can_view_documents': canViewDocuments,
      if (canUploadDocuments != null)
        'can_upload_documents': canUploadDocuments,
    };

    final response = await _execute(
      () => http.patch(
        Uri.parse('$baseUrl/caregiver-invites/permissions/$relationId'),
        headers: headers(),
        body: jsonEncode(body),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur mise à jour permissions aidant (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }


  static Future<List<Appointment>> getAppointments() async {
    final response = await _execute(
      () async => httpClient.get(
        Uri.parse('$baseUrl/appointments'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;

    return data
        .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Appointment> createAppointment({
    required String title,
    String? description,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
    bool notificationsEnabled = false,
    String? consultationType,
    int? reminderDelay,
  }) async {
    final response = await _execute(
      () async => httpClient.post(
        Uri.parse('$baseUrl/appointments'),
        headers: await careHeaders(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'notifications_enabled': notificationsEnabled,
          'consultation_type': consultationType,
          'consultationType': consultationType,
          'reminder_delay': reminderDelay,
        }),
      ),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Erreur création rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return Appointment.fromJson(_decodeJson(response) as Map<String, dynamic>);
  }

  static Future<void> deleteAppointment(int id) async {
    final response = await _execute(
      () async => httpClient.delete(
        Uri.parse('$baseUrl/appointments/$id'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Erreur suppression rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<Appointment> updateAppointment({
    required int id,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? notificationsEnabled,
    String? consultationType,
    int? reminderDelay,
  }) async {
    final response = await _execute(
      () async => http.put(
        Uri.parse('$baseUrl/appointments/$id'),
        headers: await careHeaders(),
        body: jsonEncode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (location != null) 'location': location,
          if (startTime != null) 'start_time': startTime.toIso8601String(),
          if (endTime != null) 'end_time': endTime.toIso8601String(),
          if (notificationsEnabled != null)
            'notifications_enabled': notificationsEnabled,
          'consultation_type': consultationType,
          'consultationType': consultationType,
          if (reminderDelay != null) 'reminder_delay': reminderDelay,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur modification rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return Appointment.fromJson(_decodeJson(response) as Map<String, dynamic>);
  }

  // Documents: stockage, consultation, téléchargement et QR de partage.
  static Future<List<DocumentModel>> getDocuments() async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/documents'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement documents (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;

    return data
        .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<DocumentModel> createDocument({
    required String name,
    required String type,
    String? description,
    required String fileName,
    required List<int> bytes,
  }) async {
    final response = await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/documents'),
        headers: await careHeaders(),
        body: jsonEncode({
          'name': name,
          'type': type,
          'description': description,
          'fileName': fileName,
          'contentBase64': base64Encode(bytes),
        }),
      ),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Erreur créaation document (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return DocumentModel.fromJson(
      _decodeJson(response) as Map<String, dynamic>,
    );
  }

  static Future<DocumentModel> updateDocument({
    required int id,
    String? name,
    String? type,
    String? description,
    String? fileName,
    List<int>? bytes,
  }) async {
    final response = await _execute(
      () async => http.put(
        Uri.parse('$baseUrl/documents/$id'),
        headers: await careHeaders(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (type != null) 'type': type,
          if (description != null) 'description': description,
          if (fileName != null) 'fileName': fileName,
          if (bytes != null) 'contentBase64': base64Encode(bytes),
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur modification document (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return DocumentModel.fromJson(
      _decodeJson(response) as Map<String, dynamic>,
    );
  }

  static Future<void> deleteDocument(int id) async {
    final response = await _execute(
      () async => http.delete(
        Uri.parse('$baseUrl/documents/$id'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Erreur suppression document (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  // Demande au backend une URL temporaire qui sera encodé dans le QR code.
  static Future<String> createDocumentShareLink(int id) async {
    final response = await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/documents/$id/share-link'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur lien de partage (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response) as Map<String, dynamic>;
    final link = (body['share_url'] ?? body['shareUrl'] ?? body['url'])
        ?.toString();

    if (link == null || link.trim().isEmpty) {
      throw Exception('Lien de partage absent dans la rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©ponse backend');
    }

    return link.trim();
  }

  // Stock et traitements: médicaments, inventaire, prises et rappels.
  static Future<void> deleteStock(int id) async {
    final response = await _execute(
      () async => http.delete(
        Uri.parse('$baseUrl/stock/$id'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Erreur suppression stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> deleteTreatment(int id) async {
    final response = await _execute(
      () async => http.delete(
        Uri.parse('$baseUrl/treatment/$id'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Erreur suppression traitement (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> addStock({required int id, required int amount}) async {
    final response = await _execute(
      () async => http.patch(
        Uri.parse('$baseUrl/stock/$id/add'),
        headers: await careHeaders(),
        body: jsonEncode({'amount': amount}),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur ajout stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> removeStock({
    required int id,
    required int amount,
  }) async {
    final response = await _execute(
      () async => http.patch(
        Uri.parse('$baseUrl/stock/$id/remove'),
        headers: await careHeaders(),
        body: jsonEncode({'amount': amount}),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur retrait stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> updateStock({
    required int id,
    int? quantity,
    String? location,
  }) async {
    final response = await _execute(
      () async => http.patch(
        Uri.parse('$baseUrl/stock/$id'),
        headers: await careHeaders(),
        body: jsonEncode({
          if (quantity != null) 'quantity': quantity,
          if (location != null) 'location': location,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur mise à jour stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<List<MedicationSearchResult>> searchMedications(
    String name,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/medication/nameSearch',
    ).replace(queryParameters: {'name': name});
    final response = await _execute(
      () async => http.get(uri, headers: await careHeaders()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur recherche médicament (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response);
    final List<dynamic> data;
    if (body is List) {
      data = body;
    } else if (body is Map<String, dynamic>) {
      data = (body['data'] ?? body['results'] ?? const []) as List<dynamic>;
    } else {
      data = const [];
    }

    return data
        .map((e) => MedicationSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createStock({
    required int medicationId,
    required int quantity,
    required String location,
  }) async {
    final response = await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/stock/new'),
        headers: await careHeaders(),
        body: jsonEncode({
          'medication_id': medicationId,
          'quantity': quantity,
          'location': location,
        }),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur création de stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<int> createTreatment({
    required int medicationId,
    required String frequency,
    required List<int> daysOfWeek,
    required String startDate,
    String? endDate,
  }) async {
    final response = await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/treatment/new'),
        headers: await careHeaders(),
        body: jsonEncode({
          'medication_id': medicationId,
          'dosage': '0',
          'frequency': frequency,
          'days_of_week': daysOfWeek,
          'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        }),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur création traitement (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final data = _decodeJson(response);
    if (data is Map<String, dynamic>) {
      final id =
          data['id'] ??
          (data['data'] is Map ? (data['data'] as Map)['id'] : null);
      if (id != null) return (id as num).toInt();
    }
    throw Exception('ID traitement introuvable dans la réponse');
  }

  static Future<List<TreatmentItem>> getTreatments() async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/treatment/me'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement traitements (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response);
    final List<dynamic> data;
    if (body is List) {
      data = body;
    } else if (body is Map<String, dynamic>) {
      data = (body['data'] ?? body['treatments'] ?? const []) as List<dynamic>;
    } else {
      data = const [];
    }

    return data
        .map((e) => TreatmentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<TreatmentSchedule>> getTreatmentSchedules(
    int treatmentId,
  ) async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/treatment/$treatmentId/schedules'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement créneaux (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response);
    final List<dynamic> data;
    if (body is List) {
      data = body;
    } else if (body is Map<String, dynamic>) {
      data = (body['data'] ?? body['schedules'] ?? const []) as List<dynamic>;
    } else {
      data = const [];
    }

    return data
        .map((e) => TreatmentSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addTreatmentSchedule({
    required int treatmentId,
    required String timeOfDay,
    required double quantity,
  }) async {
    final response = await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/treatment/$treatmentId/schedules'),
        headers: await careHeaders(),
        body: jsonEncode({'time_of_day': timeOfDay, 'quantity': quantity}),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur ajout créneau (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<StockSummary> getStock() async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/stock/me'),
        headers: await careHeaders(),
      ),
    );

    debugPrint('[Stock] status=${response.statusCode} body=${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return StockSummary.fromJson(_decodeJson(response) as Map<String, dynamic>);
  }

  static Future<List<IntakeItem>> getIntakesForTreatment(
    int treatmentId,
  ) async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/intake/treatment/$treatmentId'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement intakes (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = _decodeJson(response);
    debugPrint(
      '[API] intake/$treatmentId body type=${body.runtimeType} preview=${response.body.substring(0, response.body.length.clamp(0, 120))}',
    );

    final List<dynamic> data;
    if (body is List) {
      data = body;
    } else if (body is Map<String, dynamic>) {
      final raw = body['data'] ?? body['intakes'] ?? body['items'] ?? const [];
      data = raw is List ? raw : const [];
    } else {
      data = const [];
    }

    debugPrint('[API] intake/$treatmentId -> ${data.length} item(s) parses');

    return data
        .map((item) => IntakeItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> validateIntake(int intakeId) async {
    final response = await _execute(
      () async => http.patch(
        Uri.parse('$baseUrl/intake/$intakeId/validate'),
        headers: await careHeaders(),
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Erreur validation intake (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> logout() async {
    if (_refreshToken == null) {
      clearTokens();
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers(),
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
    } catch (_) {
      // On efface les tokens localement même si le backend est inaccessible.
    } finally {
      clearTokens();
    }
  }

  // Essaie plusieurs routes de téléchargement car le backend peut renvoyer un fichier brut ou du base64.
  static Future<List<int>> downloadDocument({
    required int id,
    String? fileUrl,
  }) async {
    final candidates = <Uri>[
      Uri.parse('$baseUrl/documents/$id/download'),
      Uri.parse('$baseUrl/documents/$id/file'),
      if (fileUrl != null && fileUrl.trim().isNotEmpty) Uri.parse(fileUrl),
    ];

    Object? lastError;

    for (final uri in candidates) {
      try {
        final response = await http.get(uri, headers: await careHeaders());

        if (response.statusCode != 200) {
          lastError = Exception('HTTP ${response.statusCode} on $uri');
          continue;
        }

        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final json = _decodeJson(response) as Map<String, dynamic>;
          final contentBase64 = json['contentBase64'] as String?;
          if (contentBase64 == null || contentBase64.isEmpty) {
            throw Exception('Réponse JSON sans contentBase64');
          }
          return base64Decode(contentBase64);
        }

        return response.bodyBytes;
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Téléchargement document impossible: $lastError');
  }
}
