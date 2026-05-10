import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:3000/api';

  static String? token;

  static Map<String, String> headers() {
    return {
      'Content-Type': 'application/json',
      if (token != null)
        'Authorization': 'Bearer $token',
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

    return jsonDecode(response.body);
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

    final data =
    jsonDecode(response.body)
    as Map<String, dynamic>;

    token = data['token'];

    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers(),
    );

    return jsonDecode(response.body);
  }
}