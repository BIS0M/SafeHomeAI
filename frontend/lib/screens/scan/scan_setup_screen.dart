/// [Screen] 안전 검사 준비 화면
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// [연결] 프로바이더들
import '../../../providers/scan_provider.dart';
import '../../../providers/ui_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/child_provider.dart';
import '../../../theme/app_theme.dart';

// [연결] 위젯 및 화면
import '../../../widgets/scan/room_chip.dart';
import 'media_picker_screen.dart';
import 'analysis_result_screen.dart';

class ScanSetupScreen extends StatelessWidget {
  const ScanSetupScreen({super.key});

  static const List<String> _rooms = [
    '침실',
    '아이방',
    '거실',
    '욕실',
    '놀이방',
    '주방',
    '베란다/발코니',
    '계단',
  ];

  @override
  Widget build(BuildContext context) {
    // 1. 담당자들 소환 (watch를 사용하여 상태 변화 감지)
    final scanProvider = context.watch<ScanProvider>();
    final uiProvider = context.read<UiProvider>();
    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<HistoryProvider>();

    // ✅ 상태 정의
    final bool hasResult = scanProvider.currentAnalysisRecord != null;
    final bool isShowingContent = scanProvider.isAnalyzing || hasResult;
    final selected = scanProvider.selectedRoom;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        centerTitle: false,
        // ✅ [핵심] 자동 뒤로가기 생성 막기
        automaticallyImplyLeading: false,
        // ✅ 로딩(분석 중)일 때만 뒤로가기 숨김
        leading: scanProvider.isAnalyzing
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  if (isShowingContent) {
                    // ✅ 결과 화면에서는 초기화 후 홈 탭으로 이동
                    scanProvider.clearCurrentResult();
                    try {
                      context.read<UiProvider>().setTabIndex(0);
                    } catch (_) {}
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
        // ✅ 상태에 따라 앱바 제목 변경
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isShowingContent
                  ? (scanProvider.isAnalyzing
                        ? '위험 요소 분석 중'
                        : '${scanProvider.selectedRoom} 분석 결과')
                  : '안전 검사 설정',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (!isShowingContent)
              const Text(
                '1단계 / 2단계',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),

      // ✅ 상태에 따라 body 내용물 교체
      body: isShowingContent
          ? const AnalysisResultScreen()
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '검사할 공간 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 방 선택 그리드
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.35,
                            ),
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          final isSelected = room == selected;

                          return RoomChip(
                            label: room,
                            selected: isSelected,
                            onTap: () =>
                                context.read<ScanProvider>().selectRoom(room),
                          );
                        },
                      ),
                    ),
                  ),

                  // 하단 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selected == null
                            ? null
                            : () async {
                                // 1. 미디어 선택 화면으로 이동 (중복된 코드를 제거하고 하나만 남겼습니다)
                                final XFile? file = await Navigator.of(context)
                                    .push<XFile?>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MediaPickerScreen(room: selected),
                                      ),
                                    );

                                if (file != null && context.mounted) {
                                  // 2. 아이 정보 가져오기
                                  final childProvider = context
                                      .read<ChildProvider>();
                                  final selectedChild =
                                      childProvider.selectedChild;

                                  // 3. 분석 시작 (사용자님의 스마트 알림 로직 포함)
                                  scanProvider.runAnalysisFromXFile(
                                    file,
                                    userId: authProvider.email!,
                                    token: authProvider.token!,
                                    historyProvider: historyProvider,
                                    childId: selectedChild?.id,
                                    growthStage:
                                        selectedChild?.growthStage ?? "walking",
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: selected == null
                              ? Colors.grey.shade300
                              : AppTheme.primary,
                          foregroundColor: selected == null
                              ? Colors.grey.shade600
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          '사진 촬영하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
