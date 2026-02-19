/// [Widget] 검사 프로세스 하단 버튼 바
/// 사진 선택 완료, 분석 시작 등 검사 과정의 주요 액션을 수행하는 하단 고정 버튼 영역입니다.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_theme.dart';

class AnalysisBottomNav extends StatelessWidget {
  const AnalysisBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>(); //

    return NavigationBar(
      selectedIndex: ui.tabIndex,
      onDestinationSelected: (i) {
        ui.setTabIndex(i);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
        NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: '검사하기'),
        NavigationDestination(icon: Icon(Icons.access_time), label: '기록'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: '내 정보'),
      ],
    );
  }
}
