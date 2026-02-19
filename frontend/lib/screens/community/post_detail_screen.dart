import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_theme.dart';

import '../../widgets/community/analysis_card_widget.dart';

import '../../providers/history_provider.dart';
import '../../screens/scan/analysis_result_screen.dart';
import 'write_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isCommentLoading = false;
  
  // ✅ [수정] 화면 전환 로딩 상태 관리 변수 추가
  // (불안정한 showDialog 대신 이 변수로 로딩을 제어합니다)
  bool _isNavigationLoading = false; 

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // 댓글 목록 불러오기
  Future<void> _loadComments() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiProvider>();
    if (auth.token == null) return;

    final result = await api.fetchComments(widget.post.id, auth.token!);
    if (mounted) setState(() => _comments = result);
  }

  // 댓글 작성하기
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final api = context.read<ApiProvider>();
    if (auth.token == null) return;

    setState(() => _isCommentLoading = true);
    
    final success = await api.addComment(widget.post.id, text, auth.token!);
    
    if (success && mounted) {
      _commentController.clear();
      await _loadComments();
      if (mounted) {
        context.read<CommunityProvider>().fetchPosts(context);
      }
    }
    if (mounted) setState(() => _isCommentLoading = false);
  }

  // ✅ [추가] 분석 결과 화면으로 안전하게 이동하는 함수
  Future<void> _navigateToAnalysis() async {
    if (widget.post.linkedAnalysisId == null) return;

    // 1. 로딩 시작 (다이얼로그 X, 상태 변경 O)
    setState(() => _isNavigationLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final historyProvider = context.read<HistoryProvider>();

      // 2. 데이터 가져오기
      final record = await historyProvider.loadSharedRecord(
        widget.post.linkedAnalysisId!, 
        auth.token!
      );

      if (!mounted) return;

      if (record != null) {
        // 3. 데이터가 있으면 이동
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
      debugPrint("상세화면 이동 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("오류가 발생했습니다.")),
        );
      }
    } finally {
      // 4. 로딩 끝 (무조건 실행됨)
      if (mounted) setState(() => _isNavigationLoading = false);
    }
  }
  // ✅ [추가] 게시글 삭제 로직
  void _deletePost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("게시글 삭제"),
        content: const Text("정말로 이 게시글을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // 다이얼로그 닫기
              
              // Provider를 통해 삭제 요청
              final success = await context.read<CommunityProvider>()
                  .deletePost(context, widget.post.id);
              
              if (success && mounted) {
                Navigator.pop(context); // 상세 화면 닫기 (목록으로 복귀)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("게시글이 삭제되었습니다.")),
                );
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 내 글인지 확인 (이메일 비교)
    // final currentUserEmail = context.read<AuthProvider>().user?.email;
    // final bool isMyPost = currentUserEmail == widget.post.authorId; 
    // 주의: 백엔드에서 authorId에 이메일을 주는지, 고유 ID를 주는지 확인 필요.
    // 만약 이름만 온다면 정확한 비교가 어려울 수 있으니, 일단은 true로 두고 테스트하세요.
    final bool isMyPost = true; // 테스트용 강제 true


    // ✅ [핵심] Stack을 사용하여 로딩바가 필요할 때만 화면 위에 덮어씌웁니다.
    // 이렇게 하면 페이지가 넘어가면서 로딩바가 '실종'되거나 '잔상'이 남는 일이 없습니다.
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("게시글", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            actions: [
              if (isMyPost) // 내 글일 때만 보임
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'delete') _deletePost();
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('삭제하기', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. 작성자 정보
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (widget.post.authorProfileImage != null && widget.post.authorProfileImage!.isNotEmpty)
                              ? NetworkImage(widget.post.authorProfileImage!)
                              : null,
                          child: (widget.post.authorProfileImage == null || widget.post.authorProfileImage!.isEmpty)
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              widget.post.createdAt.toString().split(' ')[0], 
                              style: const TextStyle(color: Colors.grey, fontSize: 12)
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 2. 제목 및 내용
                    Text(widget.post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(widget.post.content, style: const TextStyle(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 16),

                    // 3. 분석 공유 카드 (클릭 시 이동 로직 연결)
                    if (widget.post.linkedAnalysisId != null) ...[
                      AnalysisCardWidget(
                        title: widget.post.linkedAnalysisTitle ?? '분석 결과',
                        imageUrl: widget.post.linkedAnalysisImage,
                        onTap: _isNavigationLoading ? null : _navigateToAnalysis, // 로딩 중 클릭 방지
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 4. 이미지 리스트 (WebImageWidget 제거 -> Image.network 사용)
                    if (widget.post.imageUrls.isNotEmpty)
                      ...widget.post.imageUrls.map((url) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 500), 
                              width: double.infinity,
                              child: Image.network( // ✅ 표준 위젯 교체
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (_,__,___) => Container(
                                  height: 200,
                                  color: Colors.grey.shade100,
                                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    
                    // 5. 댓글 리스트
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text("댓글 ${_comments.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    
                    if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: Text("아직 댓글이 없습니다.\n첫 번째 댓글을 남겨보세요!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ..._comments.map((c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey, 
                          child: Icon(Icons.person, size: 16, color: Colors.white)
                        ),
                        title: Text(c.authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(c.content, style: const TextStyle(fontSize: 14)),
                        trailing: Text(
                          "${c.createdAt.month}/${c.createdAt.day}", 
                          style: const TextStyle(color: Colors.grey, fontSize: 11)
                        ),
                      )),
                  ],
                ),
              ),
              
              // 6. 하단 댓글 입력창
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "댓글을 입력하세요...",
                            hintStyle: TextStyle(
                              color: Colors.grey, // ✅ 강제 회색
                              fontWeight: FontWeight.w400,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isCommentLoading ? null : _submitComment,
                        icon: _isCommentLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.send, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ [로딩 오버레이]
        // _isNavigationLoading이 true일 때만 화면 전체를 투명한 막으로 덮고 뺑뺑이를 돌립니다.
        // 화면이 넘어가거나(_isNavigationLoading=false) 에러가 나면 즉시 사라집니다.
        if (_isNavigationLoading)
          Container(
            color: Colors.black.withOpacity(0.3), // 배경 살짝 어둡게
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}