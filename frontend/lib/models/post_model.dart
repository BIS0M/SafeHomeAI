class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileImage;
  
  final String title;
  final String content;
  final List<String> imageUrls;
  
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedUserIds;
  final int commentCount; // 댓글 수

  // 분석 결과 공유 필드
  final String? linkedAnalysisId;
  final String? linkedAnalysisTitle;
  final String? linkedAnalysisImage;

  

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfileImage,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.likeCount,
    required this.likedUserIds,
    required this.commentCount,
    this.linkedAnalysisId,
    this.linkedAnalysisTitle,
    this.linkedAnalysisImage,
  });

  factory Post.fromMap(Map<String, dynamic> map, String documentId) {
    // ✅ [핵심] 서버(Python)가 보낸 snake_case 키값을 -> 앱(Dart) 변수로 연결
    
    // 날짜 변환
    DateTime parsedDate = DateTime.now();
    if (map['created_at'] != null) {
      if (map['created_at'] is String) {
        parsedDate = DateTime.parse(map['created_at']);
      } else if (map['created_at'].toString().contains('Timestamp')) {
         // 혹시라도 구버전 데이터(Timestamp)가 올 경우 대비
         parsedDate = (map['created_at'] as dynamic).toDate();
      }
    }
    final linked = map['linked_analysis'] as Map<String, dynamic>?;
    
    return Post(
      id: documentId,
      authorId: map['author_id'] ?? '',           // author_id
      authorName: map['author_name'] ?? '익명',     // author_name
      authorProfileImage: map['author_profile_image'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? []), // image_urls
      
      createdAt: parsedDate,
      
      likeCount: (map['like_count'] ?? 0) as int,         // like_count
      likedUserIds: List<String>.from(map['liked_user_ids'] ?? []),
      commentCount: (map['comment_count'] ?? 0) as int,    // comment_count
      
      // ✅ [추가] Map에서 꺼내서 저장
      linkedAnalysisId: linked?['id'] ?? map['linked_analysis_id'], // 호환성 고려
      linkedAnalysisTitle: linked?['title'] ?? map['linked_analysis_title'],
      linkedAnalysisImage: linked?['image'] ?? map['linked_analysis_image'],
    );
  }

  Map<String, dynamic> toMap() {
    // 서버로 보낼 때도 snake_case로 맞춰주는 것이 정석입니다.
    return {
      'author_id': authorId,
      'author_name': authorName,
      'author_profile_image': authorProfileImage,
      'title': title,
      'content': content,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'liked_user_ids': likedUserIds,
      'comment_count': commentCount,
      'linked_analysis': {
        'id': linkedAnalysisId,
        'title': linkedAnalysisTitle,
        'image': linkedAnalysisImage,
      },
    };
  }
}