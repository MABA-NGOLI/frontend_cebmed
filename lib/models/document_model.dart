class DocumentModel {
  final int id;
  final String userId;
  final String name;
  final String type;
  final String? description;
  final String filePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fileUrl;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.fileUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      filePath: json['file_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fileUrl: json['file_url'] as String?,
    );
  }
}

