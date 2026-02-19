import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

class WebImageWidgetImpl extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;

  const WebImageWidgetImpl({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<WebImageWidgetImpl> createState() => _WebImageWidgetImplState();
}

class _WebImageWidgetImplState extends State<WebImageWidgetImpl> {
  static final Set<String> _registered = <String>{};
  late String _viewType;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _register(widget.imageUrl, widget.fit);
  }

  @override
  void didUpdateWidget(covariant WebImageWidgetImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl.trim() != widget.imageUrl.trim() || oldWidget.fit != widget.fit) {
      _register(widget.imageUrl, widget.fit);
    }
  }

  void _register(String rawUrl, BoxFit fit) {
    final url = rawUrl.trim();
    if (url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    _viewType = 'webimg_${base64Url.encode(utf8.encode(url))}';

    if (!_registered.contains(_viewType)) {
      _registered.add(_viewType);

      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final img = html.ImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'block'
          ..style.objectFit = _cssObjectFit(fit);

        // (표시는 보통 이걸로 충분, CORS헤더 없어도 <img>는 뜨는 경우가 많음)
        img.onError.listen((_) {
          if (mounted) setState(() => _hasError = true);
        });
        img.onLoad.listen((_) {
          if (mounted) setState(() => _hasError = false);
        });

        return img;
      });
    }

    // register만으로는 상태 갱신이 늦을 수 있어서 한번 반영
    setState(() => _hasError = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.trim().isEmpty || _hasError) {
      return Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return HtmlElementView(viewType: _viewType);
  }

  String _cssObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      case BoxFit.fitHeight:
      case BoxFit.fitWidth:
        return 'contain';
    }
  }
}
