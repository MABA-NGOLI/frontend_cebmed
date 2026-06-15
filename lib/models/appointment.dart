class Appointment {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String? location;

  final DateTime startTime;
  final DateTime endTime;

  final bool notificationsEnabled;
  final String? consultationType;
  final int? reminderDelay;

  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    required this.notificationsEnabled,
    this.consultationType,
    this.reminderDelay,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      userId: (json['user_id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      notificationsEnabled:
      (json['notifications_enabled'] ?? false) as bool,
      consultationType: (json['consultation_type'] ?? json['consultationType']) as String?,
      reminderDelay: json['reminder_delay'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'notifications_enabled': notificationsEnabled,
      'consultation_type': consultationType,
      'reminder_delay': reminderDelay,
    };
  }
}
