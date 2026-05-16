import 'user_model.dart';

class AuthTokenResponse {
  final String token;

  const AuthTokenResponse({required this.token});

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(token: json['token'] as String);
  }
}

class RegisterResponse {
  final String message;
  final UserModel? user;

  const RegisterResponse({
    required this.message,
    this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: (json['message'] ?? '') as String,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MeResponse {
  final UserModel user;

  const MeResponse({required this.user});

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

