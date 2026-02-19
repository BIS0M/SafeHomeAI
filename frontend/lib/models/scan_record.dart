import '../models/analysis_result.dart';

class ScanRecord {
  // UI/탭에서 쓰는 기존 필드 유지
  final String id;
  final String room;
  final String dateLabel;
  final int risksFound;
  final String shortSummary;
  final int createdAtMillis;

  // 이미지 URL(GCS)
  final String imageUrl;

  // ✅ 반드시 저장/복원되어야 하는 hazards
  final List<DetectedHazard> hazards;

  // 선택
  final String? childId;

  // ✅ 해결 상태 (영구 저장)
  final List<String> solvedHazardKeys;

  const ScanRecord({
    required this.id,
    required this.room,
    required this.dateLabel,
    required this.risksFound,
    required this.shortSummary,
    required this.createdAtMillis,
    required this.imageUrl,
    required this.hazards,
    this.childId,
    required this.solvedHazardKeys,
  });

  // --------------------------------------------------
  // 서버/캐시(Map) → 앱
  // --------------------------------------------------
  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    // created_at(ISO) 우선 → 없으면 createdAtMillis → 없으면 now
    DateTime created;
    final createdAtStr = json['created_at']?.toString();
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      created = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    } else {
      final millis = (json['createdAtMillis'] as num?)?.toInt();
      created = (millis != null)
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : DateTime.now();
    }

    final room = (json['space_type'] ?? json['room'] ?? '').toString();
    final risksFound = (json['hazards_count'] ?? json['risksFound'] ?? 0);
    final risksInt = (risksFound is num) ? risksFound.toInt() : 0;

    // hazards 복원: detected_hazards(서버/캐시) 또는 hazards(옛 키)
    final hazardsRaw = (json['detected_hazards'] ?? json['hazards'] ?? []) as List;
    final hazardsList = hazardsRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => DetectedHazard.fromJson(e))
        .toList();

    return ScanRecord(
      id: (json['report_id'] ?? json['id'] ?? '').toString(),
      room: room,
      dateLabel: (json['dateLabel'] ?? _toDateLabel(created)).toString(),
      risksFound: risksInt,
      shortSummary: (json['shortSummary'] ?? '위험 요소 ${risksInt}개 발견').toString(),
      createdAtMillis:
          (json['createdAtMillis'] as num?)?.toInt() ?? created.millisecondsSinceEpoch,
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      childId: json['child_id']?.toString(),

      // ✅ 핵심
      hazards: hazardsList,

      // ✅ 핵심
      solvedHazardKeys: List<String>.from(json['solved_hazard_keys'] ?? json['solvedHazardKeys'] ?? []),
    );
  }

  // --------------------------------------------------
  // 앱 → 캐시(Map) 저장용
  // --------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      // 서버 키로 저장(호환성 ↑)
      'report_id': id,
      'space_type': room,
      'image_url': imageUrl,
      'hazards_count': risksFound,
      'child_id': childId,
      'created_at': DateTime.fromMillisecondsSinceEpoch(createdAtMillis).toIso8601String(),

      // ✅ DetectedHazard는 이미 toJson()이 있음
      'detected_hazards': hazards.map((h) => h.toJson()).toList(),

      // ✅ 해결 상태 저장
      'solved_hazard_keys': solvedHazardKeys,

      // (선택) 프론트에서 쓰는 키도 같이 남기고 싶으면 아래 유지해도 됨
      'dateLabel': dateLabel,
      'shortSummary': shortSummary,
      'createdAtMillis': createdAtMillis,
    };
  }

  // --------------------------------------------------
  // solved 상태 업데이트용
  // --------------------------------------------------
  ScanRecord copyWith({
    List<String>? solvedHazardKeys,
  }) {
    return ScanRecord(
      id: id,
      room: room,
      dateLabel: dateLabel,
      risksFound: risksFound,
      shortSummary: shortSummary,
      createdAtMillis: createdAtMillis,
      imageUrl: imageUrl,
      hazards: hazards,
      childId: childId,
      solvedHazardKeys: solvedHazardKeys ?? this.solvedHazardKeys,
    );
  }
}

String _toDateLabel(DateTime dt) {
  return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
