/// [Widget] 위험 해결 체크 카드
/// 상세 페이지 최상단에서 해당 위험 요소를 해결했는지 체크박스로 확인할 수 있는 기능을 제공합니다.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ResolvedCheckCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ResolvedCheckCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final titleStyle = (textTheme.bodyMedium ?? const TextStyle(fontSize: 12)).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.1,
    );
    final subtitleStyle =
        (textTheme.labelSmall ?? textTheme.bodySmall ?? const TextStyle(fontSize: 11)).copyWith(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    return Card(
      child: Padding(
        // ✅ 박스 크기(높이) 더 줄이기
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ 체크박스(네모) 자체 크기 더 줄이기 + 터치 여백 축소
            Transform.scale(
              scale: 0.9, // 더 줄이고 싶으면 0.8
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('위험 요소를 해결했나요?', style: titleStyle),
                  const SizedBox(height: 4),
                  Text('체크하면 분석 결과에서 사라집니다', style: subtitleStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
