// lib/models/product.dart
class Product {
  final String? id;
  final String? title;
  final double? price;
  final int? stockQuantity;
  final String? categoryName;

  Product({
    this.id,
    this.title,
    this.price,
    this.stockQuantity,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String? catName = 'Uncategorized';
    if (json['categoryId'] is Map) {
      catName = json['categoryId']['name'] ?? 'Uncategorized';
    } else if (json['categoryId'] is String) {
      catName = json['categoryId'];
    }

    return Product(
      id: json['_id'],
      title: json['title'],
      price: (json['price'] as num?)?.toDouble(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
      categoryName: catName,
    );
  }
}
