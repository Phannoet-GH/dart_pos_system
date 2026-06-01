class OrderItem {
  String? productId;
  int? quantity;
  double? priceAtSale;

  OrderItem({this.productId, this.quantity, this.priceAtSale});

  OrderItem.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    quantity = json['quantity'];
    priceAtSale = json['price_at_sale'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['quantity'] = quantity;
    data['price_at_sale'] = priceAtSale;
    return data;
  }
}
