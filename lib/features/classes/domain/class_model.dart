class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String? inviteCode;
  final String? category;
  final bool isPrivate;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.inviteCode,
    this.category,
    required this.isPrivate,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      inviteCode: json['invite_code'] as String?,
      category: json['category'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
