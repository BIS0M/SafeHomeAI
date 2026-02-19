class RecommendedProduct {
  final String id;
  final String name;
  final int? price;
  final String? imageUrl;
  final String? reason;
  final String? buyUrl;

  const RecommendedProduct({
    required this.id,
    required this.name,
    this.price,
    this.imageUrl,
    this.reason,
    this.buyUrl,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toInt()
          : int.tryParse(
              (json['price']?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
            ),
      imageUrl: json['imageUrl']?.toString(),
      reason: json['reason']?.toString(),
      buyUrl: json['buyUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'reason': reason,
        'buyUrl': buyUrl,
      };
}
