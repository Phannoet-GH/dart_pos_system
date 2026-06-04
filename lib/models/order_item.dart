class OrderItem {
  String? productId;
  int? quantity;
  double? priceAtSale;

  OrderItem({this.productId, this.quantity, this.priceAtSale});

  // lib/models/order_item.dart

  OrderItem.fromJson(Map<String, dynamic> json) {
    // 🎯 FIX 4: Handle both direct ID strings or populated product object maps safely
    if (json['product_id'] != null) {
      if (json['product_id'] is Map) {
        productId = (json['product_id']['id'] ?? json['product_id']['_id'])
            ?.toString();
      } else {
        productId = json['product_id'].toString();
      }
    }

    quantity = json['quantity'] as int?;
    priceAtSale = (json['price_at_sale'] as num?)?.toDouble() ?? 0.00;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['quantity'] = quantity;
    data['price_at_sale'] = priceAtSale;
    return data;
  }
}
