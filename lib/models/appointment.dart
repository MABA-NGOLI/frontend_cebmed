class Appointment {
  final int id;
  final String userId;
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
    final parsedStart = DateTime.parse(json['start_time'] as String).toLocal();
    final parsedEnd = DateTime.parse(json['end_time'] as String).toLocal();
    final parsedCreatedAt = DateTime.parse(json['created_at'] as String).toLocal();
    final parsedUpdatedAt = DateTime.parse(json['updated_at'] as String).toLocal();

    return Appointment(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: parsedStart,
      endTime: parsedEnd,
      notificationsEnabled: (json['notifications_enabled'] ?? false) as bool,
      consultationType: json['consultation_type'] as String?,
      reminderDelay: json['reminder_delay'] as int?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'notifications_enabled': notificationsEnabled,
      'consultation_type': consultationType,
      'reminder_delay': reminderDelay,
    };
  }
}
