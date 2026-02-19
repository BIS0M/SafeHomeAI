/// [Widget] 추천 안전 제품 카드
/// 위험 해결에 필요한 안전 용품의 정보 + 구매 링크 제공

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recommended_product.dart'; // ✅ 여기로 통일
import '../../theme/app_theme.dart';
import '../web_image_widget.dart';

class ProductRecommendationCard extends StatelessWidget {
  final List<RecommendedProduct> recommendations;

  const ProductRecommendationCard({
    super.key,
    required this.recommendations,
  });

  Future<void> _launchBuyUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
    }
  }

  String _subtitleFor(RecommendedProduct p) {
    // ✅ price가 있으면 가격 표시
    if (p.price != null) return '₩${_formatPrice(p.price!)}';

    // ✅ price가 없으면 reason을 확인하되,
    // reason이 "₩48900" / "48,900원" / "48900" 같은 가격 형태면 콤마 적용
    final r = (p.reason ?? '').trim();
    if (r.isEmpty) return '';

    final digits = r.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits);

    if (parsed != null && digits.isNotEmpty) {
      return '₩${_formatPrice(parsed)}';
    }

    return r;
  }

  Widget _buildProductItem(BuildContext context, RecommendedProduct p) {
    final buyUrl = (p.buyUrl ?? '').trim();
    final subtitle = _subtitleFor(p);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52,
          height: 52,
          child: WebImageWidget(
            imageUrl: p.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        p.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
      trailing: ElevatedButton(
        onPressed: buyUrl.isEmpty ? null : () => _launchBuyUrl(context, buyUrl),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(60, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('구매하기', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (int i = 0; i < recommendations.length; i++) ...[
              if (i != 0) const Divider(height: 1),
              _buildProductItem(context, recommendations[i]),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatPrice(int price) {
  final s = price.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buffer.write(s[i]);
    final pos = s.length - i - 1;
    if (pos > 0 && pos % 3 == 0) buffer.write(',');
  }
  return buffer.toString();
}
