import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile 사용
import 'package:provider/provider.dart'; // context.read 사용

import '../models/post_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class CommunityProvider extends ChangeNotifier {
  // 게시글 목록
  List<Post> _posts = [];
  List<Post> get posts => _posts;

  // ✅ [NEW] 2. 오늘의 인기글 목록
  List<Post> _dailyBestPosts = [];
  List<Post> get dailyBestPosts => _dailyBestPosts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ------------------------------------------------------------------------
  // 1. 게시글 목록 불러오기 (Read)
  // ------------------------------------------------------------------------
  Future<void> fetchPosts(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiProvider>();

    // 토큰이 없으면(로그인 안 했으면) 조회 불가
    if (auth.token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // API에게 목록 달라고 요청
      _posts = await api.fetchCommunityPosts(auth.token!);
    } catch (e) {
      debugPrint("❌ Provider 에러: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------------
  // 2. 게시글 작성하기 (Create)
  // ------------------------------------------------------------------------
  Future<bool> addPost(BuildContext context, {
    required String title,
    required String content,
    required List<XFile> images, 
    // ✅ [수정] UI에서 Map으로 넘겨주므로, 여기서 Map으로 받습니다.
    Map<String, dynamic>? linkedAnalysis, 
  }) async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiProvider>();

    if (auth.token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // ✅ [핵심] Map에서 데이터를 꺼내서 API Provider에게 전달
      // (ApiProvider는 createCommunityPost에서 개별 필드를 원하니까요)
      final success = await api.createCommunityPost(
        token: auth.token!,
        title: title,
        content: content,
        images: images,
        // 여기서 쏙쏙 뽑아서 전달!
        linkedAnalysisId: linkedAnalysis?['id'],
        linkedAnalysisTitle: linkedAnalysis?['title'],
        linkedAnalysisImage: linkedAnalysis?['image'],
      );

      // 성공했다면 목록을 새로고침해서 내 글이 보이게 함
      if (success) {
        if (context.mounted) {
          await fetchPosts(context);
        }
      }
      return success;

    } catch (e) {
      debugPrint("❌ 글쓰기 Provider 에러: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------------
  // 3. 좋아요 토글 (Like)
  // ------------------------------------------------------------------------
  Future<bool> toggleLike(BuildContext context, String postId) async {
    final api = context.read<ApiProvider>();
    final auth = context.read<AuthProvider>();
    
    if (auth.token == null) return false;

    try {
      // 1. 서버에 요청 보내기
      final success = await api.toggleLike(postId, auth.token!); 

      // ✅ [수정] 성공 시 인기글 목록을 즉시 새로고침하여 홈 화면에 반영
      if (success) {
        // 인기글 데이터 갱신 (좋아요 수 변경 및 순위 재정렬)
        await fetchDailyBest(context); 
        
        // 필요하다면 전체 게시글 목록도 갱신 (선택사항)
        // await fetchPosts(context);
        
        notifyListeners(); // 화면 갱신 알림
      }
      
      return success;
    } catch (e) {
      debugPrint("좋아요 에러: $e");
      return false;
    }
  }
  /// ✅ 게시글 삭제 (UI에서 호출하는 함수)
  Future<bool> deletePost(BuildContext context, String postId) async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiProvider>();

    if (auth.token == null) return false;

    try {
      // API Provider에게 삭제 요청
      final success = await api.deleteCommunityPost(postId, auth.token!);
      
      if (success) {
        // 성공하면 내 폰의 목록에서도 즉시 지워줍니다 (새로고침 효과)
        _posts.removeWhere((p) => p.id == postId);
        notifyListeners(); // 화면 갱신!
      }
      return success;
    } catch (e) {
      debugPrint("❌ Provider 삭제 에러: $e");
      return false;
    }
  }
  // ------------------------------------------------------------------------
  // ✅ [NEW] 오늘의 인기글 불러오기
  // ------------------------------------------------------------------------
  Future<void> fetchDailyBest(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiProvider>();

    if (auth.token == null) return;

    try {
      // API Provider에 새로 만든 함수 호출
      _dailyBestPosts = await api.fetchDailyBestPosts(auth.token!);
      notifyListeners(); // 화면 갱신 (홈 화면 등에서 감지)
    } catch (e) {
      debugPrint("❌ Provider 인기글 에러: $e");
    }
  }
} // 클래스 끝