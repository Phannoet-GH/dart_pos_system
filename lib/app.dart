// lib/app.dart
import 'dart:io';
import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/models/cart.dart';
import 'package:dart_pos_system/services/auth_service.dart';
import 'package:dart_pos_system/services/product_service.dart';
import 'package:dart_pos_system/services/api_service.dart';
import 'package:dart_pos_system/helper/input_validator.dart';

class App {
  // Service Instances localized as private attributes within the App class scope
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final ApiService _apiService = ApiService();
  final Cart _localCart = Cart();

  /// Primary execution orchestrator loop
  Future<void> run() async {
    print('====================================================');
    print('      WELCOME TO THE DART CONSOLE POS SYSTEM       ');
    print('====================================================');

    while (true) {
      if (_authService.currentUser == null) {
        await _showLoginMenu();
      } else if (_authService.currentUser!.role == 'Admin') {
        await _showAdminMenu();
      } else if (_authService.currentUser!.role == 'Sale') {
        await _showSaleMenu();
      }
    }
  }

  // =========================================================================
  // AUTHENTICATION MENU FLOW
  // =========================================================================
  Future<void> _showLoginMenu() async {
    print('\n--- SYSTEM AUTHENTICATION ---');
    print('1. Login to POS');
    print('2. Exit Application');

    int choice = InputValidator.readInt(
      prompt: 'Select an option (1-2): ',
      min: 1,
      max: 2,
    );

    if (choice == 2) {
      print('\nThank you for using the POS system. Goodbye!');
      exit(0);
    }

    String username = InputValidator.readString(prompt: 'Username: ');
    String password = InputValidator.readPassword(prompt: 'Password: ');

    print('\n⏳ Connecting to database server...');
    await _authService.login(username: username, password: password);
  }

  // =========================================================================
  // ADMIN CONTROL WORKSPACE
  // =========================================================================
  Future<void> _showAdminMenu() async {
    print('\n====================================');
    print('        ADMIN CONTROL CENTER        ');
    print('====================================');
    print('1. Display All Products (API)');
    print('2. View Product Details (API)');
    print('3. Add New Product (API)');
    print('4. Update Product / Manage Stock (API)');
    print('5. Delete Product (API)');
    print('6. Search Products (Local)');
    print('7. View All Transaction Orders (API)');
    print('8. Logout Session');
    print('====================================');

    int choice = InputValidator.readInt(
      prompt: 'Choose an operational index (1-8): ',
      min: 1,
      max: 8,
    );

    switch (choice) {
      case 1:
        await _displayAllProducts();
        break;
      case 2:
        await _viewProductDetails();
        break;
      case 3:
        await _addNewProduct();
        break;
      case 4:
        await _updateProductInfo();
        break;
      case 5:
        await _deleteProductRecord();
        break;
      case 6:
        await _searchProductsWorkflow();
        break;
      case 7:
        await _viewAllOrdersHistory();
        break;
      case 8:
        _authService.logout();
        break;
    }
  }

  // =========================================================================
  // CASHIER / SALE CONTROL WORKSPACE
  // =========================================================================
  Future<void> _showSaleMenu() async {
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
        await _displayAllProducts();
        break;
      case 2:
        await _viewProductDetails();
        break;
      case 3:
        await _searchProductsWorkflow();
        break;
      case 4:
        await _addProductToLocalCart();
        break;
      case 5:
        _displayLocalCart();
        break;
      case 6:
        _updateCartItemQty();
        break;
      case 7:
        _removeItemFromCart();
        break;
      case 8:
        _localCart.clear();
        print('\n🛒 Active session cart cleared out successfully.');
        break;
      case 9:
        await _executeCheckoutOrder();
        break;
      case 10:
        await _viewAllOrdersHistory();
        break;
      case 11:
        _localCart.clear();
        _authService.logout();
        break;
    }
  }

  // =========================================================================
  // CORE POS API / LOGICAL WORKFLOW METHODS
  // =========================================================================
  Future<void> _displayAllProducts() async {
    print('\n--- PULLING FRESH INVENTORY LOGS ---');
    List<Product> products = await _productService.getAllProducts();
    if (products.isEmpty) {
      print('No products currently established inside the MongoDB index.');
      return;
    }
    print('------------------------------------------------------------');
    print(
      '${"ID".padRight(25)} | ${"PRODUCT NAME".padRight(35)} | ${"PRICE".padRight(10)} | ${"STOCK".padRight(6)}',
    );
    print('------------------------------------------------------------');
    for (var prod in products) {
      print(
        '${prod.id!.padRight(25)} | ${prod.title!.padRight(35)} | \$${prod.price!.toStringAsFixed(2).padRight(9)} | ${prod.stockQuantity!.toString().padRight(6)}',
      );
    }
    print('------------------------------------------------------------');
  }

  Future<void> _viewProductDetails() async {
    String id = InputValidator.readString(prompt: 'Enter Product ID string: ');
    Product? prod = await _productService.getProductDetails(id: id);
    if (prod != null) {
      print('\n📦 PRODUCT SPECIFICATIONS DETAIL RECORD:');
      print('• DB Reference ID: ${prod.id!}');
      print('• Title Identity: ${prod.title!}');
      print('• Price Matrix:   \$${prod.price!.toStringAsFixed(2)}');
      print('• Stock Balance:  ${prod.stockQuantity!.toString()} items left');
      print('• Category Rel:   ${prod.categoryId!}');
    }
  }

  Future<void> _addNewProduct() async {
    print('\n--- DESIGN NEW ENTRY LOG ---');
    String title = InputValidator.readString(prompt: 'Product Title: ');
    double price = InputValidator.readDouble(
      prompt: 'Unit Retail Price (\$): ',
      min: 0.01,
    );
    int stock = InputValidator.readInt(
      prompt: 'Starting Stock Pool Count: ',
      min: 0,
    );
    String catId = InputValidator.readString(
      prompt: 'Category reference ID code: ',
    );

    await _productService.addProduct(
      title: title,
      price: price,
      stockQuantity: stock,
      categoryId: catId,
    );
  }

  Future<void> _updateProductInfo() async {
    String id = InputValidator.readString(
      prompt: 'Enter ID of the target product to update: ',
    );
    print('\nLeave empty if you do not wish to adjust that specific field.');

    stdout.write('New Title (Press Enter to Skip): ');
    String? titleInput = stdin.readLineSync()?.trim();

    stdout.write('New Price (Press Enter to Skip): ');
    String? priceInput = stdin.readLineSync()?.trim();

    stdout.write('New Stock Level (Press Enter to Skip): ');
    String? stockInput = stdin.readLineSync()?.trim();

    Map<String, dynamic> updatedFields = {};
    if (titleInput != null && titleInput.isNotEmpty) {
      updatedFields['title'] = titleInput;
    }
    if (priceInput != null && priceInput.isNotEmpty) {
      updatedFields['price'] = double.parse(priceInput);
    }
    if (stockInput != null && stockInput.isNotEmpty) {
      updatedFields['stock_quantity'] = int.parse(stockInput);
    }

    if (updatedFields.isNotEmpty) {
      await _productService.updateProduct(id: id, updatedFields: updatedFields);
    } else {
      print('No changes submitted.');
    }
  }

  Future<void> _deleteProductRecord() async {
    String id = InputValidator.readString(
      prompt: 'Enter absolute ID target for deletion processing: ',
    );
    bool confirm = InputValidator.readConfirmation(
      prompt: '⚠️ Are you certain you want to drop this record?',
    );
    if (confirm) {
      await _productService.deleteProduct(id: id);
    }
  }

  Future<void> _searchProductsWorkflow() async {
    String query = InputValidator.readString(
      prompt: 'Enter search keywords matching product names: ',
    );
    List<Product> databaseList = await _productService.getAllProducts();
    List<Product> matches = _productService.searchProducts(
      cachedList: databaseList,
      query: query,
    );

    print('\n🔎 MATCHES FOUND: (${matches.length})');
    for (var m in matches) {
      print(
        '-> ID: ${m.id} | Title: ${m.title} | Price: \$${m.price!.toDouble().toStringAsFixed(2)} | Stock: ${m.stockQuantity!.toInt()}',
      );
    }
  }

  Future<void> _addProductToLocalCart() async {
    String id = InputValidator.readString(
      prompt: 'Enter targeted Product ID: ',
    );
    Product? prod = await _productService.getProductDetails(id: id);

    if (prod != null) {
      int qty = InputValidator.readInt(
        prompt: 'Enter purchase request quantity balance: ',
        min: 1,
      );
      if (qty > prod.stockQuantity!) {
        print(
          '❌ Request rejected. Only ${prod.stockQuantity!.toStringAsFixed(2)} items remain in stocks.',
        );
        return;
      }
      _localCart.addProduct(prod, qty);
      print('✅ Registered inside your active local temporary cart.');
    }
  }

  void _displayLocalCart() {
    if (_localCart.items.isEmpty) {
      print('\n🛒 Your operational session shopping cart is currently empty.');
      return;
    }
    print('\n🛒 --- TEMPORARY SESSION SHOPPING CART ITEMS ---');
    for (var item in _localCart.items) {
      print(
        '• [ID: ${item.product.id}] ${item.product.title} x ${item.quantity.toInt()} -> Subtotal: \$${item.subTotal.toStringAsFixed(2)}',
      );
    }
    print('-------------------------------------------------');
    print(
      'TOTAL CART BALANCE VALUE: \$${_localCart.calculateTotalPrice.toStringAsFixed(2)}',
    );
  }

  void _updateCartItemQty() {
    String id = InputValidator.readString(
      prompt: 'Enter Product ID inside the cart: ',
    );
    int qty = InputValidator.readInt(
      prompt: 'Enter completely fresh checkout quantity number: ',
      min: 0,
    );
    _localCart.updateQuantity(id, qty);
    print('🔄 Cart allocation arrays adjusted cleanly.');
  }

  void _removeItemFromCart() {
    String id = InputValidator.readString(
      prompt: 'Product ID string target for removal extraction: ',
    );
    _localCart.removeProduct(id);
    print('🗑️ Item dropped from session basket.');
  }

  Future<void> _executeCheckoutOrder() async {
    if (_localCart.items.isEmpty) {
      print(
        '❌ Operational Error: Cannot execute API checkout updates on empty arrays.',
      );
      return;
    }

    print('\nSending order checkout arrays to MongoDB engine payloads...');

    List<Map<String, dynamic>> structuredItemsPayload = _localCart.items.map((
      cartItem,
    ) {
      return {
        'product_id': cartItem.product.id,
        'quantity': cartItem.quantity.toInt(),
        'price_at_sale': cartItem.product.price!,
      };
    }).toList();

    Map<String, dynamic> orderPayload = {
      'sold_by': _authService.currentUser!.id,
      'total_price': _localCart.calculateTotalPrice,
      'items': structuredItemsPayload,
    };

    try {
      final response = await _apiService.post(
        endpoint: '/orders/checkout',
        body: orderPayload,
      );
      if (response != null) {
        print('\n==============================================');
        print(' 🎉 ORDER SECURED AND WRITTEN SUCCESSFULLY!   ');
        print('==============================================');
        print('Receipt Transaction ID: ${response['_id']}');
        print(
          'Total Bill: \$${_localCart.calculateTotalPrice.toStringAsFixed(2)}',
        );
        print('==============================================');
        _localCart.clear();
      }
    } catch (e) {
      print('\n❌ Processing Failure: $e');
    }
  }

  Future<void> _viewAllOrdersHistory() async {
    print('\n--- PULLING ALL COMPLETED ORDER LOG RECORDS ---');
    try {
      final response = await _apiService.get(endpoint: '/orders');
      if (response != null && response is List) {
        if (response.isEmpty) {
          print(
            'No historical checkout entries captured inside database archives.',
          );
          return;
        }

        for (var order in response) {
          print('\n📜 RECEIPT ID: ${order['_id']}');
          print('• Date:     ${order['order_date']}');
          print(
            '• Cashier:  ${order['sold_by'] != null ? order['sold_by']['username'] : 'System Base'}',
          );
          print('• Items Logged:');
          var items = order['items'] as List? ?? [];
          for (var item in items) {
            String pTitle = item['product_id'] != null
                ? item['product_id']['title']
                : 'Deleted Product';
            print(
              '   - $pTitle (Qty: ${item['quantity']}) @ \$${item['price_at_sale']} each',
            );
          }
          print(
            '• Paid Bill Value total: \$${(order['total_price'] as num).toDouble().toStringAsFixed(2)}',
          );
          print('--------------------------------------------------');
        }
      }
    } catch (e) {
      print('Failed to interpret data lists streams cleanly: $e');
    }
  }
}
