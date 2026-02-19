import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// [Provider]
import '../../providers/child_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_provider.dart';
import '../../models/child_profile.dart';

// [Screen]
import '../child_profile_screen.dart';
import 'scan_setup_screen.dart'; // 같은 폴더에 있다고 가정

class ChildSelectionScreen extends StatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 들어올 때 최신 데이터 불러오기
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
         context.read<ChildProvider>().fetchChildrenFromServer(auth.token!);
      } else {
         context.read<ChildProvider>().loadChildren();
      }
    });
  }

  // ✅ [수정 2] 아이 선택 시 -> 검사 설정 화면으로 이동
  void _onChildTap(Child child) {
    // 1. 선택된 아이를 Provider에 저장
    context.read<ChildProvider>().selectChild(child);

    // 2. 다음 단계(공간 선택)로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanSetupScreen()), 
    );
  }

  void _onGuestTap() {
    // 선택 없이(null) 진행 -> 백엔드에서 기본값(walking) 사용
    context.read<ChildProvider>().selectChild(null);
    
    // 다음 단계로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();
    final children = childProvider.children;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF), // 연한 배경색
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // 뒤로가기 버튼 (홈으로 이동)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            context.read<UiProvider>().setTabIndex(0);
          },
        ),
        // 제목 (2줄)
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '검사 대상 선택',
              style: TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              '검사 준비 단계', 
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: false, // 왼쪽 정렬
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // 상단 안내 문구
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '누구의 안전을 검사할까요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '아이의 발달 단계에 맞춰 위험 요소를 분석해드려요.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),

            // 아이 리스트 영역
            Expanded(
              child: children.isEmpty
                  ? _buildEmptyView()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: children.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildChildCard(children[index]);
                      },
                    ),
            ),

            // 하단 건너뛰기 버튼
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextButton(
                onPressed: _onGuestTap,
                child: const Text(
                  '선택 없이 빠른 검사하기',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // ✅ [수정 1] 플로팅 버튼 -> 아이 프로필 생성 화면으로 이동
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A68FF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChildProfileScreen(returnResultToPrevious: true)),
          ).then((_) {
             // 돌아왔을 때 목록 갱신
             final auth = context.read<AuthProvider>(); 
             if(auth.token != null) context.read<ChildProvider>().fetchChildrenFromServer(auth.token!);
          });
        },
      ),
    );
  }

  // 아이 데이터가 없을 때 보이는 화면
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.child_care, size: 60, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            '등록된 아이 프로필이 없어요.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChildProfileScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A68FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('아이 프로필 등록하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 아이 카드 디자인
  Widget _buildChildCard(Child child) {
    String simpleStage = child.growthStage.split('-').first.trim();

    return GestureDetector(
      onTap: () => _onChildTap(child),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            // 프로필 아이콘 (원형)
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face, color: Color(0xFF1A68FF), size: 30),
            ),
            const SizedBox(width: 16),
            
            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    simpleStage, 
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A68FF),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 화살표 아이콘
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}