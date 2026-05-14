import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/document_model.dart';

class ApiService {
  static final String baseUrl = _resolveBaseUrl();
  static final String _apiOrigin = _resolveApiOrigin();

  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }

  static String _resolveApiOrigin() {
    final uri = Uri.parse(baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
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

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
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
      final backendMessage = data['message']?.toString();
      throw Exception(backendMessage ?? 'Connexion impossible');
    }

    final receivedToken = data['token'] as String?;
    if (receivedToken == null || receivedToken.isEmpty) {
      throw Exception('Connexion invalide, veuillez reessayer');
    }

    token = receivedToken;
    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers(),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
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
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'notifications_enabled': notificationsEnabled,
        'consultation_type': consultationType,
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
    final Map<String, dynamic> payload = {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (startTime != null) 'start_time': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (notificationsEnabled != null) 'notifications_enabled': notificationsEnabled,
      if (consultationType != null) 'consultation_type': consultationType,
      if (reminderDelay != null) 'reminder_delay': reminderDelay,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/appointments/$id'),
      headers: headers(),
      body: jsonEncode(payload),
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
    final Map<String, dynamic> payload = {
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (fileName != null) 'fileName': fileName,
      if (bytes != null) 'contentBase64': base64Encode(bytes),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/documents/$id'),
      headers: headers(),
      body: jsonEncode(payload),
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
    final endpoint = fileUrl?.trim().isNotEmpty == true
        ? fileUrl!.trim()
        : '/api/documents/$id/download';

    final absoluteUrl = endpoint.startsWith('http')
        ? endpoint
        : '$_apiOrigin$endpoint';

    final response = await http.get(
      Uri.parse(absoluteUrl),
      headers: headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur téléchargement document (HTTP ${response.statusCode})',
      );
    }

    return response.bodyBytes;
  }

  static void clearToken() {
    token = null;
  }
}

