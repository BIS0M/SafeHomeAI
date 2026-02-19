import 'package:flutter/material.dart';
import '../../models/scan_record.dart';
import '../../screens/scan/analysis_result_screen.dart';
import '../web_image_widget.dart';

class RecentAnalysisCard extends StatelessWidget {
  final ScanRecord record;
  const RecentAnalysisCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AnalysisResultScreen(historyRecord: record)),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: record.imageUrl.isNotEmpty
                    ? WebImageWidget(imageUrl: record.imageUrl)
                    : Container(color: Colors.grey.shade200),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.room,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.dateLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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