/// [Widget] 위험 요소 정보 헤더 카드
/// 해결 방법 화면에서 선택된 위험 요소의 명칭과 위험도를 강조해서 보여주는 카드입니다.
import 'package:flutter/material.dart';
import '../../models/risk_item.dart';

class RiskHeaderCard extends StatelessWidget {
  final RiskItem risk;
  // ✅ 분석 결과에서의 번호(0-based). 전달되면 아이콘 대신 번호를 표시
  // (현재 UX 요구사항: 숫자 대신 경고 아이콘)
  final int? index;

  const RiskHeaderCard({super.key, required this.risk, this.index});

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(risk);
    final severityLabel = _severityText(risk);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: severityColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              // ✅ 숫자 대신 경고 아이콘 표시
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 위험 요소 제목(크기는 SolutionDetailScreen에서 내려주는 textTheme를 따름)
                  Text(
                    risk.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      severityLabel,
                      // ✅ '중간 위험' 글자 크기 줄이기: labelSmall 우선 사용
                      style: (textTheme.labelSmall ?? textTheme.bodySmall)?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _severityText(RiskItem risk) {
    switch (risk.severity) {
      case RiskSeverity.high:
        return "위험";
      case RiskSeverity.medium:
        return "경고";
      case RiskSeverity.low:
        return "주의";
    }
  }

  Color _severityColor(RiskItem risk) {
    switch (risk.severity) {
      case RiskSeverity.high:
        return const Color(0xFFE53935);
      case RiskSeverity.medium:
        return const Color(0xFFFFCC00);
      case RiskSeverity.low:
        return const Color(0xFF2E7D32);
    }
  }
}
