class IntakeMedication {
  const IntakeMedication({
    required this.id,
    required this.name,
    required this.pharmaceuticalForm,
  });

  final int id;
  final String name;
  final String pharmaceuticalForm;

  factory IntakeMedication.fromJson(Map<String, dynamic> json) =>
      IntakeMedication(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        pharmaceuticalForm:
            (json['pharmaceuticalForm'] ?? json['pharmaceutical_form'] ?? '') as String,
      );
}

class IntakeTreatment {
  const IntakeTreatment({
    required this.id,
    required this.dosage,
    required this.medication,
  });

  final int id;
  final String dosage;
  final IntakeMedication medication;

  factory IntakeTreatment.fromJson(Map<String, dynamic> json) =>
      IntakeTreatment(
        id: (json['id'] as num).toInt(),
        dosage: json['dosage'] as String? ?? '',
        medication: IntakeMedication.fromJson(
            json['medication'] as Map<String, dynamic>),
      );
}

class IntakeItem {
  const IntakeItem({
    required this.id,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.note,
    required this.treatment,
  });

  final int id;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final String status;
  final String? note;
  final IntakeTreatment treatment;

  bool get isPending => status == 'PENDING';
  bool get isTaken => status == 'TAKEN';
  bool get isMissed => status == 'MISSED';
  bool get isValidated => status == 'TAKEN';

  String get medicationName {
    final raw = treatment.medication.name;
    final comma = raw.indexOf(',');
    return (comma == -1 ? raw : raw.substring(0, comma)).trim();
  }

  factory IntakeItem.fromJson(Map<String, dynamic> json) => IntakeItem(
        id: (json['id'] as num).toInt(),
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        takenAt: json['taken_at'] != null
            ? DateTime.parse(json['taken_at'] as String)
            : null,
        status: json['status'] as String? ?? 'PENDING',
        note: json['note'] as String?,
        treatment: IntakeTreatment.fromJson(
            json['treatment'] as Map<String, dynamic>),
      );
}
