class NoteModel {
  final String id;
  final String classId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;

  NoteModel({
    required this.id,
    required this.classId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    String? authorName;
    if (json['profiles'] != null && json['profiles'] is Map) {
      authorName = json['profiles']['full_name'] as String?;
    }
    
    return NoteModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: authorName,
    );
  }
}
