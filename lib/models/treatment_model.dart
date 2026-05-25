class TreatmentSchedule {
  const TreatmentSchedule({
    required this.id,
    required this.timeOfDay,
    required this.quantity,
  });

  final int id;
  final String timeOfDay;
  final double quantity;

  factory TreatmentSchedule.fromJson(Map<String, dynamic> json) {
    return TreatmentSchedule(
      id: (json['id'] as num).toInt(),
      timeOfDay: json['time_of_day'] as String? ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
    );
  }
}

class TreatmentItem {
  const TreatmentItem({
    required this.id,
    required this.medicationId,
    this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    required this.status,
  });

  final int id;
  final int medicationId;
  final String? medicationName;
  final String dosage;
  final String frequency;
  final List<int> daysOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;

  factory TreatmentItem.fromJson(Map<String, dynamic> json) {
    String? medicationName;
    final med = json['medication'];
    if (med is Map<String, dynamic>) {
      medicationName = med['name'] as String?;
    }

    return TreatmentItem(
      id: (json['id'] as num).toInt(),
      medicationId: (json['medication_id'] as num).toInt(),
      medicationName: medicationName,
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      daysOfWeek: (json['days_of_week'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? '',
    );
  }
}
