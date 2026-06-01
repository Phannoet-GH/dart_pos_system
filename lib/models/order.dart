import 'package:dart_pos_system/models/order_item.dart';

class Order {
  String? id;
  String? orderDate;
  String? soldBy;
  double? totalPrice;
  List<OrderItem>? orderItems;

  Order({
    this.id,
    this.orderDate,
    this.soldBy,
    this.totalPrice,
    this.orderItems,
  });

  Order.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderDate = json['order_date'];
    soldBy = json['sold_by'];
    totalPrice = json['total_price'];
    if (json['order_items'] != null) {
      orderItems = <OrderItem>[];
      json['order_items'].forEach((v) {
        orderItems!.add(OrderItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_date'] = orderDate;
    data['sold_by'] = soldBy;
    data['total_price'] = totalPrice;
    if (orderItems != null) {
      data['order_items'] = orderItems!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
