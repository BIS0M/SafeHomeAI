import 'package:flutter/material.dart';
import '../web_image_widget.dart'; // 이미지 위젯 경로 확인해주세요

class AnalysisCardWidget extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback? onTap;

  const AnalysisCardWidget({
    super.key,
    required this.title,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim(); // ✅ 공백/빈값 안전 처리

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              // 1) 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: url.isNotEmpty
                      ? WebImageWidget(imageUrl: url, fit: BoxFit.cover)
                      : Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.blue,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // 2) 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI 안전 분석 결과",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url.isNotEmpty ? '탭하여 분석 결과 보기' : '이미지 없음 · 탭하여 분석 결과 보기',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3) 화살표
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
