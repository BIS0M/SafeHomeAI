/// [Widget] 메인 하단 내비게이션 바
/// 앱 하단에 항상 고정되어 홈, 기록, 검사, 설정 등 탭을 이동할 수 있게 해주는 공용 위젯입니다.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ui_provider.dart'; // [연결] UiProvider 사용
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    // [수정] UiProvider를 통해 현재 탭 정보를 가져오고 변경합니다.
    final ui = context.watch<UiProvider>();
    final uiRead = context.read<UiProvider>(); //클릭 이벤트용
    return NavigationBar(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primary.withOpacity(0.12),
      selectedIndex: ui.tabIndex,
      onDestinationSelected: (i) {
        // 🟢 그냥 Provider에게 "이거 눌렀어"라고 전달만 함
        // (판단은 UiProvider의 setTabIndex 안에서 알아서 함)
        context.read<UiProvider>().setTabIndex(i);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '홈',
        ),
        // 1. 커뮤니티 (✅ 추가됨)
        NavigationDestination(
          icon: Icon(Icons.forum_outlined), // 말풍선 아웃라인 아이콘
          selectedIcon: Icon(Icons.forum), // 말풍선 채워진 아이콘
          label: '커뮤니티',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: '검사하기',
        ),
        NavigationDestination(
          icon: Icon(Icons.access_time_outlined),
          selectedIcon: Icon(Icons.access_time),
          label: '기록',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '내 정보',
        ),
      ],
    );
  }
}
