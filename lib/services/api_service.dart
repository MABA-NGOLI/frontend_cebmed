import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/auth_models.dart';
import '../models/document_model.dart';

class ApiService {
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }

  static String? token;

  static Map<String, String> headers() {
    return {
      'Content-Type': 'application/json',
      ...?(token == null ? null : {'Authorization': 'Bearer $token'}),
    };
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
    token = null;
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
      token = null;
      throw Exception(
        (data['message'] ?? 'Email ou mot de passe incorrect').toString(),
      );
    }

    token = (data['token'] ?? data['access_token']) as String?;

    if (token == null || token!.isEmpty) {
      token = null;
      throw Exception('Token absent, connexion impossible');
    }

    return data;
  }

  static Future<MeResponse> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers(),
    );

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
    String? phone,
    String? picture,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers(),
      body: jsonEncode({
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

  static Future<String> createCaregiverInviteCode() async {
    final response = await http.post(
      Uri.parse('$baseUrl/caregiver-invites'),
      headers: headers(),
    );

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
    final response = await http.get(
      Uri.parse('$baseUrl/appointments'),
      headers: headers(),
    );

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
    final response = await http.post(
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
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Erreur création rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return Appointment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteAppointment(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/appointments/$id'),
      headers: headers(),
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
    final response = await http.put(
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
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur modification rendez-vous (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return Appointment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<DocumentModel>> getDocuments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/documents'),
      headers: headers(),
    );

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
    final response = await http.post(
      Uri.parse('$baseUrl/documents'),
      headers: headers(),
      body: jsonEncode({
        'name': name,
        'type': type,
        'description': description,
        'fileName': fileName,
        'contentBase64': base64Encode(bytes),
      }),
    );

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
    final response = await http.put(
      Uri.parse('$baseUrl/documents/$id'),
      headers: headers(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (description != null) 'description': description,
        if (fileName != null) 'fileName': fileName,
        if (bytes != null) 'contentBase64': base64Encode(bytes),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur modification document (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return DocumentModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteDocument(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/documents/$id'),
      headers: headers(),
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Erreur suppression document (HTTP ${response.statusCode}): ${response.body}',
      );
    }
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
}
