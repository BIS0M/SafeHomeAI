/// [Widget] 분석 결과 위험 항목 줄
/// 분석 결과 리스트에서 발견된 개별 위험 요소의 명칭과 심각도를 한 줄씩 표시합니다.
import 'package:flutter/material.dart';
import '../../models/risk_item.dart'; // [핵심] 이 줄이 있어야 빨간 줄이 사라집니다!

class RiskRowItem extends StatelessWidget {
  final RiskItem risk;
  final VoidCallback onOpen;
  final int? index; // ✅ [추가] 선택적 번호 (기존 호출부 깨지지 않음)

  const RiskRowItem({
    super.key,
    required this.risk,
    required this.onOpen,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _badgeFor(risk);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ✅ [번호] index가 들어오면 표시
              if (index != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: badge.color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index! + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              Expanded(
                child: Text(
                  risk.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badge.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Badge _badgeFor(RiskItem r) {
    switch (r.severity) {
      case RiskSeverity.high:
        return _Badge('높음', const Color(0xFFFF3B30));
      case RiskSeverity.medium:
        return _Badge('중간', const Color(0xFFFFCC00));
      case RiskSeverity.low:
        return _Badge('낮음', const Color(0xFF34C759));
    }
  }
}

// [핵심] 이 클래스가 파일 안에 포함되어 있어야 합니다!
class _Badge {
  final String label;
  final Color color;
  _Badge(this.label, this.color);
}
