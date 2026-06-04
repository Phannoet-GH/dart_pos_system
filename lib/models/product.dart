// lib/models/product.dart

class Product {
  final String? id;
  final String? title;
  final double? price;
  final int? stockQuantity;
  final String?
  categoryName; // Will store the Hex ID string or the Name based on payload structure

  Product({
    this.id,
    this.title,
    this.price,
    this.stockQuantity,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String? catValue = 'Uncategorized';

    // 🎯 STRATEGY: Handle both Flat IDs (unpopulated) and nested Sub-documents (populated)
    if (json['category_id'] != null) {
      if (json['category_id'] is Map) {
        // Option A: Backend is populated -> Extract the 'name' property directly
        catValue = json['category_id']['name']?.toString() ?? 'Uncategorized';
      } else {
        // Option B: Backend is unpopulated -> Extract the raw ID string hash to match against cache maps
        catValue = json['category_id'].toString();
      }
    }
    // Alternate key fallback (camelCase configuration variant)
    else if (json['categoryId'] != null) {
      if (json['categoryId'] is Map) {
        catValue = json['categoryId']['name']?.toString() ?? 'Uncategorized';
      } else {
        catValue = json['categoryId'].toString();
      }
    }

    return Product(
      // Maps both Mongoose default identifiers or converted id schemas smoothly
      id: (json['id'] ?? json['_id'])?.toString(),
      title: json['title'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
      categoryName: catValue,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // Keep internal payload requests mapped back to native Mongo specifications
    data['id'] = id;
    data['title'] = title;
    data['price'] = price;
    data['stock_quantity'] = stockQuantity;
    data['category_id'] = categoryName;
    return data;
  }
}
