import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../models/analysis_result.dart';
import '../../widgets/web_image_widget.dart';

/// 분석 이미지 + 위험요소 bbox 오버레이 위젯
/// - 백엔드 bbox_coords(원본 좌표)를
/// - Flutter BoxFit(기본 cover)로 렌더된 화면 좌표로 변환하여 표시
class AnalysisImageBox extends StatefulWidget {
  final String imageUrl;
  final List<DetectedHazard> hazards;
  final BoxFit fit;
  final void Function(DetectedHazard hazard)? onTapHazard;
  final int? selectedIndex;

  const AnalysisImageBox({
    super.key,
    required this.imageUrl,
    required this.hazards,
    this.fit = BoxFit.cover,
    this.onTapHazard,
    this.selectedIndex,
  });

  @override
  State<AnalysisImageBox> createState() => _AnalysisImageBoxState();
}

class _AnalysisImageBoxState extends State<AnalysisImageBox> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageNaturalSize();
  }

  @override
  void didUpdateWidget(covariant AnalysisImageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageSize = null;
      _loadImageNaturalSize();
    }
  }

  void _loadImageNaturalSize() {
    // 웹/모바일 공통으로 쓰고 싶으면 ImageStream 방식으로도 가능하지만,
    // 현재 프로젝트가 WebImageWidget + web 환경 중심이라 여기선 간단히 유지.
    // (AnalysisResultScreen 쪽에서 이미 html.ImageElement 방식 사용 중)
  }

  @override
  Widget build(BuildContext context) {
    // 이 위젯은 현재 화면에서 직접 사용되지 않을 수 있어도,
    // 동일 로직을 재사용할 수 있도록 구조를 맞춰둠.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (context, c) {
              final containerSize = Size(c.maxWidth, c.maxHeight);

              return Stack(
                fit: StackFit.expand,
                children: [
                  WebImageWidget(imageUrl: widget.imageUrl, fit: widget.fit),
                  // AnalysisImageBox는 자연 사이즈를 이 파일에서 직접 안 구하고 있어서,
                  // 필요 시 AnalysisResultScreen의 overlay 위젯을 사용하거나,
                  // 여기 자연사이즈 로딩 로직을 추가해 사용해줘.
                  // (현재 실사용은 AnalysisResultScreen의 _HazardOverlayImage에서 처리)
                  IgnorePointer(
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.black.withOpacity(0.02),
                      child: const Text(
                        'AnalysisImageBox (사용 시 자연 사이즈 로딩 추가)',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// bbox 변환 유틸 (AnalysisResultScreen 쪽에서 실제 사용)
Rect mapBboxToContainerRect({
  required List<double> bbox,
  required Size imageSize,
  required Size containerSize,
  required BoxFit fit,
}) {
  // bbox: [x1, y1, x2, y2] (원본 이미지 좌표)
  // (혹시 정규화 [0~1]로 오는 경우도 방어)
  double x1 = bbox.isNotEmpty ? bbox[0] : 0;
  double y1 = bbox.length > 1 ? bbox[1] : 0;
  double x2 = bbox.length > 2 ? bbox[2] : 0;
  double y2 = bbox.length > 3 ? bbox[3] : 0;

  final maxVal = [x1, y1, x2, y2].fold<double>(0, (m, v) => v > m ? v : m);
  if (maxVal <= 2.0 && imageSize.width > 0 && imageSize.height > 0) {
    // 정규화 좌표로 판단
    x1 *= imageSize.width;
    x2 *= imageSize.width;
    y1 *= imageSize.height;
    y2 *= imageSize.height;
  }

  // 정렬/클램프
  final left = x1 < x2 ? x1 : x2;
  final top = y1 < y2 ? y1 : y2;
  final right = x1 < x2 ? x2 : x1;
  final bottom = y1 < y2 ? y2 : y1;

  final imgRect = Rect.fromLTRB(
    left.clamp(0.0, imageSize.width),
    top.clamp(0.0, imageSize.height),
    right.clamp(0.0, imageSize.width),
    bottom.clamp(0.0, imageSize.height),
  );

  // BoxFit에 따른 source/dest 계산
  final fitted = applyBoxFit(fit, imageSize, containerSize);
  final sourceRect = Alignment.center.inscribe(fitted.source, Offset.zero & imageSize);
  final destRect = Alignment.center.inscribe(fitted.destination, Offset.zero & containerSize);

  // sourceRect 기준으로 bbox를 destRect로 선형 변환
  final sx = destRect.width / sourceRect.width;
  final sy = destRect.height / sourceRect.height;

  final mapped = Rect.fromLTRB(
    (imgRect.left - sourceRect.left) * sx + destRect.left,
    (imgRect.top - sourceRect.top) * sy + destRect.top,
    (imgRect.right - sourceRect.left) * sx + destRect.left,
    (imgRect.bottom - sourceRect.top) * sy + destRect.top,
  );

  return mapped;
}
