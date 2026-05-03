class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String? inviteCode;
  final String? category;
  final String? faculty;
  final String? major;
  final String? academicYear;
  final bool isPrivate;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.inviteCode,
    this.category,
    this.faculty,
    this.major,
    this.academicYear,
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
      faculty: json['faculty'] as String?,
      major: json['major'] as String?,
      academicYear: json['academic_year'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'invite_code': inviteCode,
      'category': category,
      'faculty': faculty,
      'major': major,
      'academic_year': academicYear,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
