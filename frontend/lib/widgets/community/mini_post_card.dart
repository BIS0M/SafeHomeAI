import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../screens/community/post_detail_screen.dart';

class MiniPostCard extends StatelessWidget {
  final Post post;
  
  const MiniPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // 1. 분석 결과 포함 여부
    final bool hasAnalysis = post.linkedAnalysisId != null;
    
    // 2. 표시할 썸네일 이미지 결정 (분석 이미지 우선 -> 없으면 업로드 이미지 -> 없으면 null)
    String? thumbnailUrl;
    if (post.linkedAnalysisImage != null && post.linkedAnalysisImage!.isNotEmpty) {
      thumbnailUrl = post.linkedAnalysisImage;
    } else if (post.imageUrls.isNotEmpty) {
      thumbnailUrl = post.imageUrls.first;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
      },
      child: Container(
        width: 280, // 가로 너비 고정
        margin: const EdgeInsets.only(bottom: 5), // 그림자 잘림 방지
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // 1. 썸네일 영역 (이미지가 있으면 이미지, 없는데 분석글이면 파란박스)
            // ---------------------------------------------------------
            if (thumbnailUrl != null)
              _buildImageThumbnail(thumbnailUrl, hasAnalysis) // 이미지 + 뱃지
            else if (hasAnalysis)
              _buildAnalysisFallback(post.linkedAnalysisTitle ?? "AI 안전 분석 결과") // 이미지 없는 분석글
            else
              const SizedBox(height: 16), // 이미지도 분석도 없으면 여백만

            const SizedBox(height: 12),

            // ---------------------------------------------------------
            // 2. 텍스트 영역
            // ---------------------------------------------------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일이 없을 때만 작성자 정보 표시 (공간 활용)
                    if (thumbnailUrl == null && !hasAnalysis) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (post.authorProfileImage != null)
                                ? NetworkImage(post.authorProfileImage!)
                                : null,
                            child: (post.authorProfileImage == null)
                                ? const Icon(Icons.person, size: 10, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.authorName,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 제목
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // 내용
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 13, 
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: (thumbnailUrl != null || hasAnalysis) ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------------
            // 3. 하단 정보 (좋아요, 댓글, 날짜)
            // ---------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.favorite, size: 14, color: Colors.redAccent.shade100),
                  const SizedBox(width: 4),
                  Text(
                    "${post.likeCount}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble, size: 14, color: Colors.blueAccent.shade100),
                  const SizedBox(width: 4),
                  Text(
                    "${post.commentCount}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 [위젯] 이미지 썸네일 (분석글이면 뱃지 추가)
  Widget _buildImageThumbnail(String imageUrl, bool showBadge) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          // 1. 배경 이미지
          SizedBox(
            height: 120, 
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                );
              },
            ),
          ),
          // 2. AI 분석 뱃지 (이미지 위에 뜸)
          if (showBadge)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 12, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      "AI 분석 결과",
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 [위젯] 이미지가 없는 분석글일 때 (파란 박스 대체)
  Widget _buildAnalysisFallback(String title) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF), // 연한 파랑
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(Icons.analytics_outlined, size: 80, color: Colors.blue.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "AI 분석 결과",
                    style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1E3A8A)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) return "${diff.inHours}시간 전";
    return "${date.month}월 ${date.day}일";
  }
}