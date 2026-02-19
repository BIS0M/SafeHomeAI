/// [Widget] 공간별 안전 상태 요약 카드
/// 홈 화면 그리드에 표시되며, 각 방(거실, 주방 등)의 현재 안전 등급을 직관적으로 보여줍니다.
import 'package:flutter/material.dart';
import '../../models/scan_record.dart';
import '../../screens/scan/analysis_result_screen.dart';
import '../web_image_widget.dart'; // 위젯 임포트

// 실제 데이터가 있는 녹색 카드
class ActiveRoomCard extends StatelessWidget {
  final ScanRecord record;
  const ActiveRoomCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // ✅ 클릭 시 상세 화면으로 이동하며 데이터 전달
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(historyRecord: record),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          children: [
            // 1) 배경 이미지 (방 사진)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: record.imageUrl.isNotEmpty
                    ? WebImageWidget(imageUrl: record.imageUrl)
                    : Container(color: Colors.grey.shade300),
              ),
            ),
            // 2) 이미지 위에 어두운 오버레이 (글씨를 잘 보이게 함)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // 3) 정보 텍스트
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    record.room,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: record.risksFound > 0 ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.risksFound > 0 ? '위험 ${record.risksFound}' : '안전',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 스켈레톤 카드는 기존 스타일 유지 (혹은 비슷하게 수정)
class SkeletonRoomCard extends StatelessWidget {
  const SkeletonRoomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: const Center(child: Icon(Icons.add, color: Colors.grey)),
    );
  }
}