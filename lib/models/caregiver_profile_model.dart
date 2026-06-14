class CaregiverProfileModel {
  final int? relationId;
  final int? patientId;
  final String firstName;
  final String lastName;
  final String? picture;
  final String status;
  final bool canViewAgenda;
  final bool canEditAgenda;
  final bool canViewDocuments;
  final bool canUploadDocuments;
  final bool canViewStock;
  final bool canEditStock;
  final bool canViewProfile;

  const CaregiverProfileModel({
    this.relationId,
    this.patientId,
    required this.firstName,
    required this.lastName,
    this.picture,
    required this.status,
    this.canViewAgenda = false,
    this.canEditAgenda = false,
    this.canViewDocuments = false,
    this.canUploadDocuments = false,
    this.canViewStock = false,
    this.canEditStock = false,
    this.canViewProfile = false,
  });

  String get fullName {
    final value = ('$firstName $lastName').trim();
    return value.isEmpty ? 'Profil' : value;
  }

  factory CaregiverProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) {
      return value is Map<String, dynamic> ? value : null;
    }

    bool asBool(String key, {bool fallback = false}) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return fallback;
    }

    final patient =
        asMap(json['patient']) ??
        asMap(json['caregiver']) ??
        asMap(json['user']) ??
        asMap(json['profile']);

    final firstName =
        (patient?['firstName'] ??
                patient?['first_name'] ??
                json['firstName'] ??
                json['first_name'] ??
                '')
            .toString();
    final lastName =
        (patient?['lastName'] ??
                patient?['last_name'] ??
                json['lastName'] ??
                json['last_name'] ??
                '')
            .toString();

    return CaregiverProfileModel(
      relationId: (json['id'] as num?)?.toInt(),
      patientId:
          ((patient?['id'] ?? json['user_id'] ?? json['patient_id']) as num?)
              ?.toInt(),
      firstName: firstName,
      lastName: lastName,
      picture: (patient?['picture'] ?? json['picture'])?.toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      canViewAgenda: asBool('can_view_agenda'),
      canEditAgenda: asBool('can_edit_agenda'),
      canViewDocuments: asBool('can_view_documents'),
      canUploadDocuments: asBool('can_upload_documents'),
      canViewStock: asBool('can_view_stock'),
      canEditStock: asBool('can_edit_stock'),
      canViewProfile: asBool('can_view_profile'),
    );
  }
}
