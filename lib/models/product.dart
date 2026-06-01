class Product {
  String? id;
  String? title;
  double? price;
  int? stockQuantity;
  String? categoryId;

  Product({
    this.id,
    this.title,
    this.price,
    this.stockQuantity,
    this.categoryId,
  });

  Product.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    price = json['price'];
    stockQuantity = json['stock_quantity'];
    categoryId = json['category_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['price'] = price;
    data['stock_quantity'] = stockQuantity;
    data['category_id'] = categoryId;
    return data;
  }
}
