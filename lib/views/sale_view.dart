// lib/views/sale_view.dart
import 'package:dart_pos_system/helper/input_validator.dart';

class SaleView {
  /// Entry logic loop routing choices to specific checkout cart management functions
  static Future<void> handleWorkflow(dynamic appScope) async {
    print('\n====================================');
    print('         CASHIER SALE PANEL         ');
    print('====================================');
    print('1. Display All Products (API)');
    print('2. View Product Details (API)');
    print('3. Search Products (Local)');
    print('4. Add Product to Cart (Local)');
    print('5. View Active Basket Cart (Local)');
    print('6. Update Cart Item Quantity (Local)');
    print('7. Remove Product from Cart (Local)');
    print('8. Clear Active Cart Items (Local)');
    print('9. Finalize Order Checkout (API)');
    print('10. View Transaction Orders History (API)');
    print('11. Logout Session');
    print('====================================');

    int choice = InputValidator.readInt(
      prompt: 'Select cashier workspace line (1-11): ',
      min: 1,
      max: 11,
    );

    switch (choice) {
      case 1:
        await appScope.displayAllProducts();
        break;
      case 2:
        await appScope.viewProductDetails();
        break;
      case 3:
        await appScope.searchProductsWorkflow();
        break;
      case 4:
        await addProductToLocalCart(appScope);
        break;
      case 5:
        displayLocalCart(appScope);
        break;
      case 6:
        updateCartItemQty(appScope);
        break;
      case 7:
        removeItemFromCart(appScope);
        break;
      case 8:
        appScope.clearLocalCart();
        break;
      case 9:
        await appScope.executeCheckoutOrder();
        break;
      case 10:
        await appScope.viewAllOrdersHistory();
        break;
      case 11:
        appScope.logoutSession();
        break;
    }
  }

  /// Checkout Cart Function: Allocates units inside local list arrays
  static Future<void> addProductToLocalCart(dynamic appScope) async {
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    var prod = await appScope.productService.getProductDetails(id: realId);
    if (prod != null) {
      int currentStock = prod.stockQuantity ?? 0;
      int qty = InputValidator.readInt(
        prompt: 'Enter purchase request quantity balance: ',
        min: 1,
      );

      if (qty > currentStock) {
        print('❌ Request rejected. Only $currentStock items remain in stocks.');
        return;
      }
      appScope.localCart.addProduct(prod, qty);
      print('✅ Registered inside your active local temporary cart.');
    } else {
      print('❌ Target product does not exist.');
    }
  }

  /// Terminal Presentation Function: Formats clean row charts tracking selected items
  static void displayLocalCart(dynamic appScope) {
    var cart = appScope.localCart;
    if (cart.items.isEmpty) {
      print('\n🛒 Your operational session shopping cart is currently empty.');
      return;
    }
    print('\n🛒 --- TEMPORARY SESSION SHOPPING CART ITEMS ---');
    for (var item in cart.items) {
      print(
        '• ${item.product.title ?? "Unknown Item"} x ${item.quantity.toInt()} -> Subtotal: \$${item.subTotal.toStringAsFixed(2)}',
      );
    }
    print('-------------------------------------------------');
    print(
      'TOTAL CART BALANCE VALUE: \$${cart.calculateTotalPrice.toStringAsFixed(2)}',
    );
  }

  /// Checkout Cart Function: Overwrites values inside user session lists
  static void updateCartItemQty(dynamic appScope) {
    if (appScope.localCart.items.isEmpty) {
      print('\n🛒 Cart is empty.');
      return;
    }
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    int qty = InputValidator.readInt(
      prompt: 'Enter completely fresh checkout quantity number: ',
      min: 0,
    );
    appScope.localCart.updateQuantity(realId, qty);
    print('🔄 Cart allocation arrays adjusted cleanly.');
  }

  /// Checkout Cart Function: Drops a specific line item row inside basket indexes
  static void removeItemFromCart(dynamic appScope) {
    if (appScope.localCart.items.isEmpty) {
      print('\n🛒 Cart is empty.');
      return;
    }
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    appScope.localCart.removeProduct(realId);
    print('🗑️ Item dropped from session basket.');
  }
}
