/// [Widget] 선택/목록 그리드
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'action_tile.dart';
import 'dart:typed_data';

class SelectedGrid extends StatelessWidget {
  // ✅ 선택된 1장(0~1개)
  final List<XFile> files;

  // ✅ 불러온 목록(미선택 포함)
  final List<XFile> galleryItems;

  // ✅ 갤러리 타일 탭 선택/해제
  final ValueChanged<XFile>? onTapGallery;

  // ✅ 현재 선택된 갤러리 항목(0~1)
  final XFile? selectedGalleryItem;

  // ✅ 샘플
  final List<String> sampleAssets;
  final ValueChanged<String>? onTapSample;
  final String? selectedSampleAsset;

  // ✅ 카메라
  final VoidCallback onAddCamera;

  const SelectedGrid({
    super.key,
    required this.files,
    required this.onAddCamera,
    this.galleryItems = const [],
    this.onTapGallery,
    this.selectedGalleryItem,
    this.sampleAssets = const [],
    this.onTapSample,
    this.selectedSampleAsset,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 목록은 galleryItems를 우선으로 사용(미선택 표시 목적)
    final items = galleryItems;

    final int totalCount = 1 + sampleAssets.length + items.length;

    // 하단 안내문용 선택 수(단일 선택이지만 명확히 표기)
    final int selectedCount =
        (selectedSampleAsset != null ? 1 : 0) + (selectedGalleryItem != null ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: totalCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, i) {
                // 0: 카메라
                if (i == 0) {
                  return ActionTile(
                    icon: Icons.photo_camera_outlined,
                    label: '카메라',
                    onTap: onAddCamera,
                  );
                }

                // 샘플 영역
                final int sampleEnd = 1 + sampleAssets.length;
                if (i < sampleEnd) {
                  final path = sampleAssets[i - 1];
                  final isSelected = selectedSampleAsset == path;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onTapSample == null ? null : () => onTapSample!(path),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(path, fit: BoxFit.cover),

                          // ✅ 항상 보이는 선택 원(빈 원/선택 시 1)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: _SelectBadge(isSelected: isSelected),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 갤러리(불러온 목록) 영역
                final int idx = i - sampleEnd;
                final XFile f = items[idx];
                final bool isSelected =
                    selectedGalleryItem != null && selectedGalleryItem!.path == f.path;

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTapGallery == null ? null : () => onTapGallery!(f),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _XFileThumb(file: f),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: _SelectBadge(isSelected: isSelected),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '선택된 사진 ${selectedCount}장 · 오른쪽 위 “완료”를 누르면 분석이 시작돼요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SelectBadge extends StatelessWidget {
  final bool isSelected;
  const _SelectBadge({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF3B3B3B) : Colors.white,
        border: isSelected ? null : Border.all(color: const Color(0xFFD0D5DD), width: 2),
      ),
      child: isSelected
          ? const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _XFileThumb extends StatelessWidget {
  final XFile file;
  const _XFileThumb({required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: file.readAsBytes(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const ColoredBox(
            color: Color(0xFFF2F4F7),
            child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        return Image.memory(
          Uint8List.fromList(snap.data!),
          fit: BoxFit.cover,
        );
      },
    );
  }
}
