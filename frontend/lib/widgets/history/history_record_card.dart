import 'package:flutter/material.dart';
import '../../models/scan_record.dart';

class HistoryRecordCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback onTap;

  const HistoryRecordCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 남은 위험 개수 = 전체 hazards - solved
    final solvedSet = record.solvedHazardKeys.toSet();
    final int total = record.hazards.length;
    final int remaining = record.hazards.where((h) => !solvedSet.contains(h.hazardKey)).length;

    // 혹시 hazards가 비어있고 risksFound만 있는 레거시 record면 fallback
    final int remainingSafe = (total > 0) ? remaining : record.risksFound;
    final bool allSolved = total > 0 ? (remainingSafe == 0) : (record.risksFound == 0);

    final String summaryText = allSolved
        ? '모든 위험 요소를 해결했어요'
        : '남은 위험 요소 ${remainingSafe}개';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 왼쪽 이미지 영역
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 80,
                  color: Colors.grey.shade100,
                  child: Stack(
                    children: [
                      // 실제 분석 이미지 표시
                      record.imageUrl.isNotEmpty
                          ? Image.network(
                              record.imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.broken_image)),
                            )
                          : const Center(child: Icon(Icons.image_outlined)),

                      // ✅ 우상단 배지: 남은 개수 / 모두 해결이면 체크
                      Positioned(
                        top: 4,
                        right: 4,
                        child: allSolved
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E), // green
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 12, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      '해결',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444), // red
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$remainingSafe',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 오른쪽 정보 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.room,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.dateLabel,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // ✅ 실시간 요약 문구
                    Text(
                      summaryText,
                      style: TextStyle(
                        color: allSolved ? const Color(0xFF16A34A) : Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: allSolved ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
