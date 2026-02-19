/// [Model] 개별 위험 요소 데이터 모델
/// AI 분석 결과로 발견된 개별 위험 항목의 상세 정보(항목명, 위험 수위, 위험 사유 등)를 정의합니다.
/// 상세 해결 방법 화면(SolutionDetailScreen)에서 데이터를 표시할 때 핵심적으로 사용됩니다.
enum RiskSeverity { high, medium, low }

class RiskItem {
  final String id;
  final String title;
  final RiskSeverity severity;

  /// "왜 위험한가요?" 섹션에 들어갈 본문 (줄바꿈 포함)
  final String reason;

  const RiskItem({
    required this.id,
    required this.title,
    required this.severity,
    required this.reason,
  });

  String get severityLabel {
    switch (severity) {
      case RiskSeverity.high:
        return '높은 위험';
      case RiskSeverity.medium:
        return '중간 위험';
      case RiskSeverity.low:
        return '낮은 위험';
    }
  }
}
