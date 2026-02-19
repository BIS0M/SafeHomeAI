import 'package:flutter/material.dart';

class WebImageWidgetImpl extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const WebImageWidgetImpl({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return const Center(child: Icon(Icons.image_not_supported));
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}
