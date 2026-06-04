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

  // lib/models/order.dart

  Order.fromJson(Map<String, dynamic> json) {
    // 🎯 FIX 1: Check both clean 'id' and MongoDB native '_id'
    id = (json['id'] ?? json['_id'] ?? 'Unknown ID').toString();

    orderDate = json['order_date'] ?? json['createdAt'];

    // 🎯 FIX 2: Safely extract username if backend populated 'sold_by' as an object
    if (json['sold_by'] != null) {
      if (json['sold_by'] is Map) {
        soldBy =
            json['sold_by']['username'] ?? json['sold_by']['name'] ?? 'Cashier';
      } else {
        soldBy = json['sold_by'].toString();
      }
    } else {
      soldBy = 'System Base';
    }

    totalPrice = (json['total_price'] as num?)?.toDouble() ?? 0.00;

    // 🎯 FIX 3: Check both 'order_items' AND 'items' keys to match your checkout payload
    var rawItems = json['order_items'] ?? json['items'];
    if (rawItems != null && rawItems is List) {
      orderItems = <OrderItem>[];
      for (var v in rawItems) {
        if (v is Map<String, dynamic>) {
          orderItems!.add(OrderItem.fromJson(v));
        }
      }
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
