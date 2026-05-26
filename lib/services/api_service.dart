import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appointment.dart';
import '../models/auth_models.dart';
import '../models/document_model.dart';
import '../models/intake_model.dart';
import '../models/stock_model.dart';
import '../models/treatment_model.dart';

class ApiService {
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

  /// Appelé quand le refresh token est expiré/invalide → rediriger vers le login.
  static VoidCallback? onSessionExpired;

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
    if (access != null && access.isNotEmpty && refresh != null && refresh.isNotEmpty) {
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

  // Exécute une requête et relance automatiquement après refresh si 401.
  static Future<http.Response> _execute(Future<http.Response> Function() call) async {
    final response = await call();
    if ((response.statusCode == 401 || response.statusCode == 403) && _refreshToken != null) {
      await refresh();
      return call();
    }
    return response;
  }

  static Future<void> refresh() async {
    if (_refreshToken == null) {
      onSessionExpired?.call();
      throw Exception('Session expirée, veuillez vous reconnecter');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': _refreshToken}),
    );

    if (response.statusCode != 200) {
      _accessToken = null;
      _refreshToken = null;
      await clearTokensPersisted();
      onSessionExpired?.call();
      throw Exception('Session expirée, veuillez vous reconnecter');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    await _saveTokens();
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

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        (data['message'] ?? 'Inscription impossible').toString(),
      );
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
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

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

  static Future<MeResponse> getMe() async {
    final response = await _execute(() => http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers(),
    ));

    if (response.statusCode != 200) {
      throw Exception('Erreur profil (HTTP ${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
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

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['user'] is Map<String, dynamic>) {
      return MeResponse.fromJson(body);
    }
    return MeResponse.fromJson({'user': body});
  }

  static Future<void> deleteMyAccount({
    required String password,
  }) async {
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
    final response = await _execute(() => http.post(
      Uri.parse('$baseUrl/caregiver-invites'),
      headers: headers(),
    ));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur code de partage (HTTP ${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    final dynamic data = body['data'];
    final dynamic invite = body['invite'];

    final code = (
      body['code'] ??
      body['invite_code'] ??
      (data is Map<String, dynamic> ? data['code'] : null) ??
      (data is Map<String, dynamic> ? data['invite_code'] : null) ??
      (invite is Map<String, dynamic> ? invite['code'] : null) ??
      (invite is Map<String, dynamic> ? invite['invite_code'] : null)
    )?.toString();

    if (code == null || code.trim().isEmpty) {
      throw Exception('Code de partage absent dans la réponse backend');
    }

    return code.trim();
  }

  static Future<List<Appointment>> getAppointments() async {
    final response = await _execute(() => http.get(
      Uri.parse('$baseUrl/appointments'),
      headers: headers(),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;

    return data.map((item) => Appointment.fromJson(item as Map<String, dynamic>)).toList();
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
    final response = await _execute(() => http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: headers(),
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
    ));

    if (response.statusCode != 201) {
      throw Exception(
        'Erreur création rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return Appointment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteAppointment(int id) async {
    final response = await _execute(() => http.delete(
      Uri.parse('$baseUrl/appointments/$id'),
      headers: headers(),
    ));

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
    final response = await _execute(() => http.put(
      Uri.parse('$baseUrl/appointments/$id'),
      headers: headers(),
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (startTime != null) 'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime.toIso8601String(),
        if (notificationsEnabled != null) 'notifications_enabled': notificationsEnabled,
        'consultation_type': consultationType,
        'consultationType': consultationType,
        if (reminderDelay != null) 'reminder_delay': reminderDelay,
      }),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur modification rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return Appointment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<DocumentModel>> getDocuments() async {
    final response = await _execute(() => http.get(
      Uri.parse('$baseUrl/documents'),
      headers: headers(),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement documents (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;

    return data.map((item) => DocumentModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<DocumentModel> createDocument({
    required String name,
    required String type,
    String? description,
    required String fileName,
    required List<int> bytes,
  }) async {
    final response = await _execute(() => http.post(
      Uri.parse('$baseUrl/documents'),
      headers: headers(),
      body: jsonEncode({
        'name': name,
        'type': type,
        'description': description,
        'fileName': fileName,
        'contentBase64': base64Encode(bytes),
      }),
    ));

    if (response.statusCode != 201) {
      throw Exception(
        'Erreur création document (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return DocumentModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<DocumentModel> updateDocument({
    required int id,
    String? name,
    String? type,
    String? description,
    String? fileName,
    List<int>? bytes,
  }) async {
    final response = await _execute(() => http.put(
      Uri.parse('$baseUrl/documents/$id'),
      headers: headers(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (description != null) 'description': description,
        if (fileName != null) 'fileName': fileName,
        if (bytes != null) 'contentBase64': base64Encode(bytes),
      }),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur modification document (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return DocumentModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteDocument(int id) async {
    final response = await _execute(() => http.delete(
      Uri.parse('$baseUrl/documents/$id'),
      headers: headers(),
    ));

    if (response.statusCode != 204) {
      throw Exception(
        'Erreur suppression document (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> deleteStock(int id) async {
    final response = await _execute(() => http.delete(
      Uri.parse('$baseUrl/stock/$id'),
      headers: headers(),
    ));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Erreur suppression stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> deleteTreatment(int id) async {
    final response = await _execute(() => http.delete(
      Uri.parse('$baseUrl/treatment/$id'),
      headers: headers(),
    ));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Erreur suppression traitement (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> addStock({required int id, required int amount}) async {
    final response = await _execute(() => http.patch(
      Uri.parse('$baseUrl/stock/$id/add'),
      headers: headers(),
      body: jsonEncode({'amount': amount}),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur ajout stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> removeStock({required int id, required int amount}) async {
    final response = await _execute(() => http.patch(
      Uri.parse('$baseUrl/stock/$id/remove'),
      headers: headers(),
      body: jsonEncode({'amount': amount}),
    ));

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
    final response = await _execute(() => http.patch(
      Uri.parse('$baseUrl/stock/$id'),
      headers: headers(),
      body: jsonEncode({
        if (quantity != null) 'quantity': quantity,
        if (location != null) 'location': location,
      }),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur mise à jour stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<List<MedicationSearchResult>> searchMedications(String name) async {
    final uri = Uri.parse('$baseUrl/medication/nameSearch')
        .replace(queryParameters: {'name': name});
    final response = await _execute(() => http.get(uri, headers: headers()));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur recherche médicament (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
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
    final response = await _execute(() => http.post(
      Uri.parse('$baseUrl/stock/new'),
      headers: headers(),
      body: jsonEncode({
        'medication_id': medicationId,
        'quantity': quantity,
        'location': location,
      }),
    ));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur création stock (HTTP ${response.statusCode}): ${response.body}',
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
    final response = await _execute(() => http.post(
      Uri.parse('$baseUrl/treatment/new'),
      headers: headers(),
      body: jsonEncode({
        'medication_id': medicationId,
        'dosage': '0',
        'frequency': frequency,
        'days_of_week': daysOfWeek,
        'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      }),
    ));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur création traitement (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      final id = data['id'] ?? (data['data'] is Map ? (data['data'] as Map)['id'] : null);
      if (id != null) return (id as num).toInt();
    }
    throw Exception('ID traitement introuvable dans la réponse');
  }

  static Future<List<TreatmentItem>> getTreatments() async {
    final response = await _execute(() => http.get(
      Uri.parse('$baseUrl/treatment/me'),
      headers: headers(),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement traitements (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
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

  static Future<List<TreatmentSchedule>> getTreatmentSchedules(int treatmentId) async {
    final response = await _execute(() => http.get(
      Uri.parse('$baseUrl/treatment/$treatmentId/schedules'),
      headers: headers(),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement créneaux (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
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
    final response = await _execute(() => http.post(
      Uri.parse('$baseUrl/treatment/$treatmentId/schedules'),
      headers: headers(),
      body: jsonEncode({
        'time_of_day': timeOfDay,
        'quantity': quantity,
      }),
    ));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur ajout créneau (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<StockSummary> getStock() async {
    final response = await _execute(() => http.get(
      Uri.parse('$baseUrl/stock/me'),
      headers: headers(),
    ));

    debugPrint('[Stock] status=${response.statusCode} body=${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement stock (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return StockSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

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
        final response = await http.get(uri, headers: headers());

        if (response.statusCode != 200) {
          lastError = Exception('HTTP ${response.statusCode} on $uri');
          continue;
        }

        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
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

  static Future<List<IntakeItem>> getIntakesForTreatment(int treatmentId) async {
    final response = await _execute(() => http.get(
      Uri.parse('$baseUrl/intake/treatment/$treatmentId'),
      headers: headers(),
    ));

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur chargement intakes (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    debugPrint('[API] intake/$treatmentId body type=${body.runtimeType} preview=${response.body.substring(0, response.body.length.clamp(0, 120))}');
    final List<dynamic> data;
    if (body is List) {
      data = body;
    } else if (body is Map<String, dynamic>) {
      final raw = body['data'] ?? body['intakes'] ?? body['items'] ?? const [];
      data = raw is List ? raw : const [];
    } else {
      data = const [];
    }
    debugPrint('[API] intake/$treatmentId → ${data.length} item(s) parsé(s)');

    return data
        .map((e) => IntakeItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> validateIntake(int intakeId) async {
    final response = await _execute(() => http.patch(
      Uri.parse('$baseUrl/intake/$intakeId/validate'),
      headers: headers(),
    ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Erreur validation intake (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }
}
