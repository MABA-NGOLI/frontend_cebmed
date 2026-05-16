class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String email;
  final String? phone;
  final String? picture;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    required this.email,
    this.phone,
    this.picture,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      firstName: (json['firstName'] ?? json['first_name'] ?? '') as String,
      lastName: (json['lastName'] ?? json['last_name'] ?? '') as String,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : (json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'] as String)
              : null),
      email: json['email'] as String,
      phone: json['phone'] as String?,
      picture: json['picture'] as String?,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null),
    );
  }
}

