import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/post_model.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/community/post_detail_screen.dart';
import '../../widgets/web_image_widget.dart';
import 'analysis_card_widget.dart';

import '../../providers/history_provider.dart';
import '../../screens/scan/analysis_result_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likeCount;

  // ✅ [수정 1] 화면 전환 로딩 상태 관리 변수
  bool _isNavigationLoading = false;

  @override
  void initState() {
    super.initState();
    _initLikeState();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likeCount != widget.post.likeCount) {
      _initLikeState();
    }
  }

  void _initLikeState() {
    final currentUserId = context.read<AuthProvider>().email;
    isLiked = widget.post.likedUserIds.contains(currentUserId);
    likeCount = widget.post.likeCount;
  }

  void _handleLike() async {
    final provider = context.read<CommunityProvider>();

    setState(() {
      if (isLiked) {
        isLiked = false;
        likeCount--;
      } else {
        isLiked = true;
        likeCount++;
      }
    });

    await provider.toggleLike(context, widget.post.id);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final hasProfile = (post.authorProfileImage ?? '').trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ✅ [수정 2] Stack을 사용하여 로딩 오버레이를 카드 위에 올릴 준비
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 100));
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1) 헤더 (작성자)
                    Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: hasProfile
                                ? WebImageWidget(
                                    imageUrl: post.authorProfileImage!.trim(),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.person, color: Colors.grey, size: 20),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(post.createdAt),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        // 우측 상단 좋아요/카운트 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLiked ? Colors.redAccent.withOpacity(0.10) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isLiked ? Colors.redAccent.withOpacity(0.20) : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                                size: 16,
                                color: isLiked ? Colors.redAccent : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$likeCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isLiked ? Colors.redAccent : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 2) 내용
                    Text(
                      post.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.content,
                      style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 3) 분석 공유 카드
                    if (post.linkedAnalysisId != null) ...[
                      const SizedBox(height: 12),
                      AnalysisCardWidget(
                        title: post.linkedAnalysisTitle ?? '분석 결과',
                        imageUrl: post.linkedAnalysisImage,
                        // ✅ [수정 3] showDialog 제거 -> 상태 기반 로딩 로직 적용
                        onTap: _isNavigationLoading ? null : () async {
                          // 1. 로딩 시작
                          setState(() => _isNavigationLoading = true);

                          try {
                            final auth = context.read<AuthProvider>();
                            final historyProvider = context.read<HistoryProvider>();

                            // 2. 데이터 가져오기
                            final record = await historyProvider.loadSharedRecord(
                              post.linkedAnalysisId!,
                              auth.token!,
                            );

                            if (!mounted) return;

                            if (record != null) {
                              // 3. 성공 시 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnalysisResultScreen(historyRecord: record),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("분석 결과를 불러올 수 없습니다.")),
                              );
                            }
                          } catch (e) {
                            debugPrint("이동 에러: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("오류가 발생했습니다.")),
                              );
                            }
                          } finally {
                            // 4. 로딩 종료 (무조건 실행)
                            if (mounted) {
                              setState(() => _isNavigationLoading = false);
                            }
                          }
                        },
                      ),
                    ],

                    // 4) 이미지 리스트 (가로 스크롤)
                    if (post.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.imageUrls.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: WebImageWidget(
                                  imageUrl: post.imageUrls[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // 5) 하단 버튼 (좋아요 / 댓글)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _handleLike,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: isLiked ? Colors.redAccent : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "$likeCount",
                                  style: TextStyle(
                                    color: isLiked ? Colors.redAccent : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                "${post.commentCount}",
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ [수정 4] 로딩 오버레이 (카드 크기에 맞춰 덮어씌움)
          if (_isNavigationLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3), // 배경을 살짝 어둡게 처리
                  borderRadius: BorderRadius.circular(16), // 카드의 둥근 모서리와 일치시킴
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}