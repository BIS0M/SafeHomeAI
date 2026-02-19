/// [Widget] 권장 조치 사항 리스트
/// 발견된 위험을 안전하게 해결하기 위한 단계별 행동 지침을 번호 순서대로 나열합니다.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ActionListCard extends StatelessWidget {
  // ✅ 백엔드 연동 데이터
  // - /api/analyze 응답의 detected_hazards[*].action_plan (List<String>)
  final List<String> actionPlan;

  const ActionListCard({super.key, required this.actionPlan});

  /// 백엔드에서 내려온 조치 문장을 "제목 + 본문" 형태로 분리합니다.
  ///
  /// 지원 포맷:
  /// - "제목: 설명" 처럼 구분자가 있으면 그대로 분리
  /// - 구분자가 없으면 제목을 `조치 n`으로 자동 생성하고, 문장 전체를 본문으로 사용
  ///
  /// 반환값은 record로 (title, body) 형태입니다.
  ({String title, String body}) _splitStep(String text, int index) {
    final t = text.trim();
    if (t.isEmpty) {
      return (title: '조치 ${index + 1}', body: '');
    }

    // ✅ 문자열을 "제목/설명" 형태로 보이게 하기 위한 분리 규칙
    // - 백엔드가 "제목: 설명" 같은 포맷으로 내려주면 그대로 제목/본문 분리
    // - 구분자가 없으면 "조치 n" + 문장(본문) 형태로 표시
    const delimiters = [':', ' - ', ' – ', ' — ', '\n'];
    for (final d in delimiters) {
      final i = t.indexOf(d);
      if (i > 0) {
        final title = t.substring(0, i).trim();
        final body = t.substring(i + d.length).trim();
        if (title.isNotEmpty && body.isNotEmpty) {
          return (title: title, body: body);
        }
      }
    }

    // 구분자가 없으면 본문만 표시(제목은 기본값)
    return (title: '조치 ${index + 1}', body: t);
  }

  @override
  Widget build(BuildContext context) {
    final steps = actionPlan
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);

    if (steps.isEmpty) {
      // ✅ 데이터가 없으면 카드 자체를 숨김(빈 UI 방지)
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(steps.length, (index) {
            final (title: title, body: body) = _splitStep(steps[index], index);
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == steps.length - 1 ? 0 : 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
