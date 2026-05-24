class MedicationSearchResult {
  const MedicationSearchResult({
    required this.id,
    required this.name,
    required this.pharmaceuticalForm,
    this.cisCode,
  });

  final int id;
  final String name;
  final String pharmaceuticalForm;
  final String? cisCode;

  factory MedicationSearchResult.fromJson(Map<String, dynamic> json) {
    return MedicationSearchResult(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      pharmaceuticalForm:
          (json['pharmaceuticalForm'] ?? json['pharmaceutical_form'] ?? '') as String,
      cisCode: json['cisCode'] as String? ?? json['cis_code'] as String?,
    );
  }
}

class StockMedication {
  const StockMedication({
    required this.id,
    required this.cisCode,
    required this.name,
    required this.pharmaceuticalForm,
  });

  final int id;
  final String cisCode;
  final String name;
  final String pharmaceuticalForm;

  factory StockMedication.fromJson(Map<String, dynamic> json) {
    return StockMedication(
      id: (json['id'] as num).toInt(),
      cisCode: json['cisCode'] as String,
      name: json['name'] as String,
      pharmaceuticalForm: json['pharmaceuticalForm'] as String,
    );
  }
}

class StockItem {
  const StockItem({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.quantity,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.medication,
  });

  final int id;
  final int userId;
  final int medicationId;
  final int quantity;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StockMedication medication;

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      medicationId: (json['medication_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      location: json['location'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      medication: StockMedication.fromJson(json['medication'] as Map<String, dynamic>),
    );
  }
}

class StockSummary {
  const StockSummary({required this.count, required this.items});

  final int count;
  final List<StockItem> items;

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    return StockSummary(
      count: (json['count'] as num).toInt(),
      items: (json['data'] as List<dynamic>)
          .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
