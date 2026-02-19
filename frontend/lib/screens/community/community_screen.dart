import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/community_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/post_card.dart';
import 'write_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ [수정] 화면 시작 시 게시글 불러오기 (context 전달)
    Future.microtask(() {
      if (mounted) {
        context.read<CommunityProvider>().fetchPosts(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final communityProvider = context.watch<CommunityProvider>();
    final posts = communityProvider.posts;
    final isLoading = communityProvider.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text(
          '커뮤니티',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // 검색 기능 (추후 구현)
            },
          ),
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: () async {
          // ✅ [수정] 당겨서 새로고침할 때도 context 전달
          await context.read<CommunityProvider>().fetchPosts(context);
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : posts.isEmpty
                ? _buildEmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final post = posts[index]; // 편의상 변수로 추출
                      return PostCard(
                        // ✅ [핵심 수정] 2단계: Key 추가!
                        // 리스트가 새로고침되어도 이 ID를 가진 카드는 '재활용'하라고 알려줍니다.
                        // 이렇게 하면 이미지를 다시 로딩하지 않아 깜빡임이 사라집니다.
                        key: ValueKey(post.id), 
                        
                        post: post,
                      );
                    },
                  ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (_) => const WritePostScreen()),
           );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('글쓰기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            '아직 게시글이 없어요.\n첫 번째 글을 작성해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}