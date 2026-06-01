import 'package:dart_pos_system/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
  double get subTotal => product.price! * quantity;
}
