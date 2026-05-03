class MaterialModel {
  final String id;
  final String classId;
  final String uploadedBy;
  final String title;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;
  final String? authorName;

  MaterialModel({
    required this.id,
    required this.classId,
    required this.uploadedBy,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
    this.authorName,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    String? authorName;
    if (json['profiles'] != null && json['profiles'] is Map) {
      authorName = json['profiles']['full_name'] as String?;
    }
    
    return MaterialModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      title: json['title'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String? ?? 'unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: authorName,
    );
  }
}
