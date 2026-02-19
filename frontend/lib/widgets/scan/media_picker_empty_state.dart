/// [Widget] 미디어 피커 빈 상태 안내
/// 아직 선택된 사진이 없을 때 화면 중앙에 표시되는 사진 추가 가이드 UI입니다.
import 'package:flutter/material.dart';

class MediaPickerEmptyState extends StatelessWidget {
  final VoidCallback onCamera;

  const MediaPickerEmptyState({super.key, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 54,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            const Text(
              '사진을 선택해 주세요',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '상단 “갤러리”를 눌러 갤러리에서 선택하거나\n카메라로 바로 촬영할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('카메라'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
