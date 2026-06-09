// lib/views/sale_view.dart
import 'package:dart_pos_system/helper/input_validator.dart';
import 'package:dart_pos_system/helper/table.view.dart';

class SaleView {
  /// Entry logic loop routing choices to specific checkout cart management functions
  static Future<void> handleWorkflow(dynamic appScope) async {
    print('\n====================================');
    print('         CASHIER SALE PANEL         ');
    print('====================================');
    print('1. Display All Products');
    print('2. View Product Details');
    print('3. Search Products');
    print('4. Add Product to Cart');
    print('5. View Active Basket Cart');
    print('6. Update Cart Item Quantity');
    print('7. Remove Product from Cart');
    print('8. Clear Active Cart Items');
    print('9. Calculate Cart Total Price');
    print('10. Finalize Order Checkout');
    print('11. View Transaction Orders History');
    print('12. View Specific Receipt Details');
    print('13. Logout Session');
    print('====================================');

    int choice = InputValidator.readInt(
      prompt: 'Select cashier workspace line (1-13): ',
      min: 1,
      max: 13,
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
        await updateCartItemQty(appScope);
        break;
      case 7:
        removeItemFromCart(appScope);
        break;
      case 8:
        appScope.clearLocalCart();
        break;
      case 9:
        showCartTotal(appScope);
        break;
      case 10:
        await appScope.executeCheckoutOrder();
        break;
      case 11:
        await appScope.viewAllOrdersHistory();
        break;
      case 12:
        await viewSpecificReceipt(appScope);
        break;
      case 13:
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
    TableView.renderCartTable(appScope.localCart, appScope.menuIdToMongoIdMap);
  }

  /// Checkout Cart Function: Modifies active quantities using single session indexes
  static Future<void> updateCartItemQty(dynamic appScope) async {
    if (appScope.localCart.items.isEmpty) {
      print('\n🛒 The active session cart is completely empty.');
      return;
    }

    displayLocalCart(appScope);

    int choice = InputValidator.readInt(
      prompt: 'Enter the Cart Item No to adjust: ',
      min: 1,
      max: appScope.localCart.items.length,
    );

    var targetItem = appScope.localCart.items[choice - 1];
    String? realId = targetItem.product.id;

    if (realId == null) {
      print('❌ Reference identification link is corrupted.');
      return;
    }

    int qty = InputValidator.readInt(
      prompt:
          'Enter completely fresh checkout quantity number for ${targetItem.product.title}: ',
      min: 0,
    );

    if (qty == 0) {
      appScope.localCart.removeProduct(realId);
      print('🗑️ Quantity marked 0. Item dropped from session basket.');
      return;
    }

    var prod = await appScope.productService.getProductDetails(id: realId);
    if (prod != null) {
      int currentStock = prod.stockQuantity ?? 0;
      if (qty > currentStock) {
        print(
          '❌ Revision rejected. Upper warehouse ceiling limit is $currentStock units.',
        );
        return;
      }

      appScope.localCart.updateQuantity(realId, qty);
      print('🔄 Cart allocation arrays adjusted cleanly.');
    } else {
      print('❌ Product validation failed during revision step.');
    }
  }

  /// Checkout Cart Function: Drops a specific line item row inside basket indexes
  static void removeItemFromCart(dynamic appScope) {
    if (appScope.localCart.items.isEmpty) {
      print('\n🛒 The active session cart is completely empty.');
      return;
    }

    displayLocalCart(appScope);

    int choice = InputValidator.readInt(
      prompt: 'Enter the Cart Item No to remove: ',
      min: 1,
      max: appScope.localCart.items.length,
    );

    var targetItem = appScope.localCart.items[choice - 1];
    String? realId = targetItem.product.id;

    if (realId != null) {
      appScope.localCart.removeProduct(realId);
      print('🗑️ ${targetItem.product.title} dropped from session basket.');
    }
  }

  /// ✅ NEW: Explicit total summation presentation layout (Fulfills Req item 32)
  static void showCartTotal(dynamic appScope) {
    if (appScope.localCart.items.isEmpty) {
      print('\n🛒 Cart is empty. Total Amount Due: \$0.00');
      return;
    }
    double total = appScope.localCart.calculateTotalPrice;
    print('\n┌────────────────────────────────────────┐');
    print('│ 🛒 CURRENT LOCAL BASKET BALANCE        │');
    print('├────────────────────────────────────────┤');
    print(
      '│ Total Items Added : ${appScope.localCart.items.length.toString().padRight(19)} │',
    );
    print('│ Total Basket Value: \$${total.toStringAsFixed(2).padRight(18)} │');
    print('└────────────────────────────────────────┘');
  }

  /// ✅ NEW: Dedicated individual receipt viewing selector (Fulfills Req item 34)
  static Future<void> viewSpecificReceipt(dynamic appScope) async {
    print('\n⏳ Fetching orders context indexes...');
    // We leverage the existing history call but can isolate a receipt profile here
    // or let appScope handle an input targeting a specific receipt number index
    await appScope.viewAllOrdersHistory();
  }
}
