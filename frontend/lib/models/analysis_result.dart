import 'risk_item.dart';
import 'recommended_product.dart';

class AnalysisResult {
  final String? reportId;
  final String? resultImageUrl;
  final DateTime? createdAt;
  final List<DetectedHazard> hazards;
  final List<RecommendedProduct> recommendations;

  const AnalysisResult({
    this.reportId,
    this.resultImageUrl,
    this.createdAt,
    this.hazards = const [],
    this.recommendations = const <RecommendedProduct>[],
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final img = (json['image_url'] ?? json['origin_image_url'] ?? '').toString();

    final hazardsRaw = (json['detected_hazards'] ?? json['data'] ?? []) as List;
    final List<DetectedHazard> hazardsList = hazardsRaw
        .whereType<Map<String, dynamic>>()
        .map((h) => DetectedHazard.fromJson(h))
        .toList();

    DateTime? created;
    final createdAtStr = json['created_at']?.toString();
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        created = DateTime.parse(createdAtStr);
      } catch (_) {
        created = null;
      }
    }

    return AnalysisResult(
      reportId: (json['report_id'] ?? json['id'])?.toString(),
      resultImageUrl: img.isEmpty ? null : img,
      createdAt: created,
      hazards: hazardsList,
      recommendations: const <RecommendedProduct>[],
    );
  }
}

class DetectedHazard {
  final String title; // UI 타이틀 (hazard_name)
  final String riskLevel; // '주의'/'경고'/'위험'
  final String reason; // reason_why
  final String? summary; // Gemini 요약(없을 수 있음)
  final RiskSeverity severity;

  /// bbox: [x1, y1, x2, y2]
  final List<double> bbox;

  final List<String> actionPlan;
  final List<RecommendedProduct> recommendations;

  const DetectedHazard({
    required this.title,
    required this.riskLevel,
    required this.reason,
    required this.severity,
    this.summary,
    this.bbox = const [0.0, 0.0, 0.0, 0.0],
    this.actionPlan = const [],
    this.recommendations = const <RecommendedProduct>[],
  });

  /// ✅ 해결 체크용 고유키 (title + bbox)
  String get hazardKey {
    final bboxStr = bbox.map((v) => v.toStringAsFixed(3)).join(',');
    return '$title|$bboxStr';
  }

  Map<String, dynamic> toJson() => {
        'hazard_name': title,
        'risk_level': riskLevel,
        'summary': summary,
        'reason_why': reason.replaceAll('\n', '\\n'),
        'severity': severity.name,
        'bbox_coords': bbox,
        'action_plan': actionPlan,
        'recommended_products': recommendations.map((e) => e.toJson()).toList(),
      };

  RiskItem toRiskItem() => RiskItem(
        id: title,
        title: title,
        severity: severity,
        reason: reason,
      );

  factory DetectedHazard.fromJson(Map<String, dynamic> json) {
    final title =
        (json['hazard_name'] ?? json['item_name'] ?? '위험 요소').toString();

    final rawLevel = (json['risk_level'] ?? json['level'] ?? '경고')
        .toString()
        .trim();
    final String uiLevel = _normalizeLevel(rawLevel);

    final String? summary = (json['summary'] ?? json['short_summary'])
        ?.toString()
        .trim();
    final String? summarySafe =
        (summary != null && summary.isNotEmpty) ? summary : null;

    final reason = (json['reason_why'] ?? json['advice'] ?? '')
        .toString()
        .replaceAll('\\n', '\n');

    final bboxAny = (json['bbox_coords'] ?? json['bbox'] ?? [0, 0, 0, 0]);
    final List<double> bbox = _parseBbox(bboxAny);

    final List<String> actionPlan = (json['action_plan'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    final List<RecommendedProduct> recs = [];
    final dynamic recData =
        json['recommended_products'] ?? json['products'] ?? json['commerce_info'];

    if (recData is List) {
      for (final item in recData) {
        if (item is Map<String, dynamic>) {
          recs.add(RecommendedProduct.fromJson(item));
        }
      }
    } else if (recData is Map<String, dynamic>) {
      recs.add(RecommendedProduct.fromJson(recData));
    }

    final RiskSeverity sev = (uiLevel == '위험')
        ? RiskSeverity.high
        : (uiLevel == '주의' ? RiskSeverity.low : RiskSeverity.medium);

    return DetectedHazard(
      title: title,
      riskLevel: uiLevel,
      reason: reason,
      summary: summarySafe,
      severity: sev,
      bbox: bbox,
      actionPlan: actionPlan,
      recommendations: recs,
    );
  }
}

String _normalizeLevel(String level) {
  final l = level.toLowerCase();
  if (level == '위험' || l == 'high' || level == '높음') return '위험';
  if (level == '주의' || l == 'low' || level == '낮음') return '주의';
  return '경고';
}

List<double> _parseBbox(dynamic bboxAny) {
  try {
    if (bboxAny is List) {
      final nums = bboxAny.map((e) => (e as num).toDouble()).toList();
      if (nums.length >= 4) return nums.sublist(0, 4);
    }
  } catch (_) {}
  return const [0.0, 0.0, 0.0, 0.0];
}
