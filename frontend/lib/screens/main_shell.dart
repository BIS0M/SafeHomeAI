import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
// [연결] 탭 관리 담당자 연결
import '../providers/ui_provider.dart';

// [연결] 하단 내비게이션 바
import '../widgets/bottom_nav.dart';

// [연결] 각 탭의 화면들
import 'home_screen.dart';
import 'community/community_screen.dart'; // ✅ 커뮤니티 화면 추가
import 'scan/child_selection_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 각 탭별로 독립적인 네비게이션을 관리하기 위한 키들
  final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _communityNavigatorKey =
      GlobalKey<NavigatorState>(); // ✅ 추가됨
  final GlobalKey<NavigatorState> _scanNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _historyNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>();
  // ✨ [추가] 리로드 신호 감지용 변수
  int _lastRefreshCount = 0;

  @override
  Widget build(BuildContext context) {
    final uiProvider = context.watch<UiProvider>();
    // ✅ 1. 실제 분석 상태를 가지고 있는 ScanProvider를 직접 감시합니다.
    final scanProvider = context.watch<ScanProvider>();

    final int tab = uiProvider.tabIndex;

    // [추가 3] "같은 탭 클릭" 신호 감지 -> 첫 화면으로 이동(Pop)
    if (uiProvider.refreshCount > _lastRefreshCount) {
      _lastRefreshCount = uiProvider.refreshCount;

      // 🛑 [수정] uiProvider 대신 scanProvider.isAnalyzing을 직접 체크합니다.
      // 이렇게 해야 분석 엔진의 실제 상태와 한 치의 오차 없이 연동됩니다.
      if (!(tab == 2 && scanProvider.isAnalyzing)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = _getNavigatorKey(tab).currentState;

          if (navigator != null && navigator.canPop()) {
            navigator.popUntil((route) => route.isFirst);

            if (tab == 2) {
              // ✅ 데이터 초기화도 명확하게 수행
              scanProvider.clearCurrentResult();
            }
          }
        });
      } else {
        // 분석 중일 때는 리셋 로직이 이 지점에서 차단되어 아무 일도 일어나지 않습니다.
        debugPrint("현재 ScanProvider가 분석 중이므로 리셋을 방어합니다.");
      }
    }

    return WillPopScope(
      onWillPop: () async {
        // 0. 홈 탭
        if (tab == 0) {
          final bool canPopInternal =
              await (_homeNavigatorKey.currentState?.maybePop() ??
                  Future.value(false));
          return !canPopInternal;
        }

        // 1. ✅ 커뮤니티 탭 (추가됨)
        if (tab == 1) {
          final bool canPopInternal =
              await (_communityNavigatorKey.currentState?.maybePop() ??
                  Future.value(false));
          return !canPopInternal;
        }

        // 2. 검사 탭 (인덱스 1 -> 2 변경)
        if (tab == 2) {
          final bool canPopInternal =
              await (_scanNavigatorKey.currentState?.maybePop() ??
                  Future.value(false));
          return !canPopInternal;
        }

        // 3. 기록 탭 (인덱스 2 -> 3 변경)
        if (tab == 3) {
          final bool canPopInternal =
              await (_historyNavigatorKey.currentState?.maybePop() ??
                  Future.value(false));
          return !canPopInternal;
        }

        // 4. [수정됨] 내 정보 탭도 내부 이동이 생겼으므로 Back 처리 추가
        if (tab == 4) {
          final bool canPopInternal =
              await (_profileNavigatorKey.currentState?.maybePop() ??
                  Future.value(false));
          return !canPopInternal;
        }

        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: tab,
          children: [
            // 0. 홈 (Navigator 적용)
            Navigator(
              key: _homeNavigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              },
            ),

            // 1. ✅ 커뮤니티 (Navigator 적용 - 글쓰기 화면 이동 등 위해 필요)
            Navigator(
              key: _communityNavigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (_) => const CommunityScreen(),
                );
              },
            ),

            // 2. 검사 (Navigator 적용)
            Navigator(
              key: _scanNavigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (_) => const ChildSelectionScreen(),
                );
              },
            ),

            // 3. 기록 (Navigator 적용)
            Navigator(
              key: _historyNavigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(builder: (_) => const HistoryScreen());
              },
            ),

            // 4. [수정됨] 내 정보 (Navigator 추가)
            Navigator(
              key: _profileNavigatorKey, // 위에서 만든 키 연결
              onGenerateRoute: (settings) {
                return MaterialPageRoute(builder: (_) => const ProfileScreen());
              },
            ),
          ],
        ),
        bottomNavigationBar: const BottomNav(),
      ),
    );
  }

  // [보조 함수] 탭 번호에 맞는 키를 가져오는 단순한 함수
  GlobalKey<NavigatorState> _getNavigatorKey(int tab) {
    switch (tab) {
      case 0:
        return _homeNavigatorKey;
      case 1:
        return _communityNavigatorKey;
      case 2:
        return _scanNavigatorKey;
      case 3:
        return _historyNavigatorKey;
      case 4:
        return _profileNavigatorKey;
      default:
        return _homeNavigatorKey;
    }
  }
}
