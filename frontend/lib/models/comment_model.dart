class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String documentId) {
    // 날짜 파싱 (String -> DateTime)
    DateTime parsedDate = DateTime.now();
    if (map['created_at'] != null) {
      if (map['created_at'] is String) {
        parsedDate = DateTime.parse(map['created_at']);
      } else if (map['created_at'].toString().contains('Timestamp')) {
        parsedDate = (map['created_at'] as dynamic).toDate();
      }
    }

    return Comment(
      id: documentId,
      authorId: map['author_id'] ?? '',         // author_id
      authorName: map['author_name'] ?? '익명',   // author_name
      content: map['content'] ?? '',
      createdAt: parsedDate,                    // created_at
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author_id': authorId,
      'author_name': authorName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}