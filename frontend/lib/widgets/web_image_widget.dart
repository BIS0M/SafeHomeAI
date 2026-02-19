import 'package:flutter/material.dart';

// 조건부 import: 웹이면 web, 아니면 io를 가져옵니다.
import 'web_image_widget_io.dart'
    if (dart.library.html) 'web_image_widget_web.dart';

class WebImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const WebImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 여기서 "WebImageWidgetImpl" 클래스를 그대로 생성해야 합니다.
    return WebImageWidgetImpl(
      imageUrl: imageUrl,
      fit: fit,
    );
  }
}
