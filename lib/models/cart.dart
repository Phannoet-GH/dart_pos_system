import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/models/cart_item.dart';

class Cart {
  // Local list handling for temporary session elements
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Add product to cart (Local)
  void addProduct(Product product, int quantity) {
    for (var item in _items) {
      if (item.product.id == product.id) {
        item.quantity += quantity;
        return;
      }
    }
    _items.add(CartItem(product: product, quantity: quantity));
  }

  // Update cart quantity
  void updateQuantity(String productId, int newQuantity) {
    for (var item in _items) {
      if (item.product.id == productId) {
        if (newQuantity <= 0) {
          removeProduct(productId);
        } else {
          item.quantity = newQuantity;
        }
        return;
      }
    }
  }

  // Remove product from cart
  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
  }

  // Clear cart
  void clear() {
    _items.clear();
  }

  // Calculate total price
  double get calculateTotalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.subTotal);
  }
}
