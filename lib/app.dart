// lib/app.dart
import 'dart:io';
import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/models/cart.dart';
import 'package:dart_pos_system/services/auth_service.dart';
import 'package:dart_pos_system/services/product_service.dart';
import 'package:dart_pos_system/services/api_service.dart';
import 'package:dart_pos_system/helper/input_validator.dart';
import 'package:dart_pos_system/views/admin_view.dart';
import 'package:dart_pos_system/views/sale_view.dart';

class App {
  // ✅ Publicly exposed infrastructure instances for the UI presentation layer
  final AuthService authService = AuthService();
  final ProductService productService = ProductService();
  final ApiService apiService = ApiService();
  final Cart localCart = Cart();

  // ✅ FIXED: Removed underscores (_) to make caches public. View layers can now read maps safely!
  final Map<int, String> menuIdToMongoIdMap = {};
  final Map<int, String> menuIdToCategoryIdMap = {};

  /// System Runtime Execution Loop
  Future<void> run() async {
    print('====================================================');
    print('       WELCOME TO THE DART CONSOLE POS SYSTEM       ');
    print('====================================================');

    while (true) {
      final user = authService.currentUser;

      if (user == null) {
        await _showLoginMenu();
      } else if (user.role == 'Admin') {
        await AdminView.handleWorkflow(this);
      } else if (user.role == 'Sale') {
        await SaleView.handleWorkflow(this);
      } else {
        print('\n⚠️ Unauthorized Role configuration detected. Logging out...');
        logoutSession();
      }
    }
  }

  // =========================================================================
  // CORE INFRASTRUCTURE UTILITIES / ROUTING PLUGINS
  // =========================================================================

  /// Clears active running operations and terminates session context variables safely
  void logoutSession() {
    localCart.clear();
    menuIdToMongoIdMap
        .clear(); // 🧹 Wipe internal maps clean to prevent leakage
    menuIdToCategoryIdMap.clear();
    authService.logout();
    print('\n🔒 Session terminated safely. Logged out.');
  }

  /// Flushes local active item arrays out of shopping context
  void clearLocalCart() {
    localCart.clear();
    print('\n🛒 Active session cart cleared out successfully.');
  }

  /// Translates a terminal item index key back to its true MongoDB Hex string.
  String? getMongoIdFromNoInput() {
    // 1. Verify that the cache index matrix isn't uninitialized or stale
    if (menuIdToMongoIdMap.isEmpty) {
      print('\n⚠️ Operational Block: Product map is currently empty.');
      print(
        '👉 Please select option [1] to pull a fresh product list stream first.',
      );
      return null;
    }

    // 2. Read input with hard boundary limits matching the current map index range size
    int inputNo = InputValidator.readInt(
      prompt: 'Enter Product List Number (No): ',
      min: 1,
      max: menuIdToMongoIdMap.length,
    );

    // 3. Fail-safe extraction check
    String? realMongoId = menuIdToMongoIdMap[inputNo];
    if (realMongoId == null || realMongoId.isEmpty) {
      print(
        '❌ Execution Fault: Selection resolved to an empty or invalid reference key.',
      );
      return null;
    }

    return realMongoId;
  }

  /// Cross-routing bridging links enabling SaleView to leverage AdminView workflows directly
  Future<void> viewProductDetailsDirect() => AdminView.viewProductDetails(this);
  Future<void> searchProductsDirect() => AdminView.searchProductsWorkflow(this);

  // =========================================================================
  // BACKEND API LOGIC PIPELINES
  // =========================================================================

  /// Handles input credential verification requests
  Future<void> _showLoginMenu() async {
    print('\n--- SYSTEM AUTHENTICATION ---');
    print('1. Login to POS');
    print('2. Exit Application');
    int choice = InputValidator.readInt(
      prompt: 'Select an option : ',
      min: 1,
      max: 2,
    );
    if (choice == 2) {
      print('\nGoodbye!');
      exit(0);
    }

    String username = InputValidator.readString(prompt: 'Username: ');
    String password = InputValidator.readPassword(prompt: 'Password: ');
    print('\n⏳ Connecting to authentication server...');

    final loginResult = await authService.login(
      username: username,
      password: password,
    );

    if (loginResult == null) {
      print(
        '\n❌ Login failed. Please verify your credentials and try again.\n',
      );
    }
  }

  /// Synchronizes active payload inventory structures from remote database clusters
  Future<void> displayAllProducts() async {
    print('\n--- PULLING FRESH INVENTORY LOGS ---');
    List<Product> products = await productService.getAllProducts();
    if (products.isEmpty) {
      print('No products inside the MongoDB index.');
      return;
    }

    menuIdToMongoIdMap.clear();
    print('-' * 75);
    print(
      '${"NO".padRight(5)} | ${"PRODUCT NAME".padRight(45)} | ${"PRICE".padRight(10)} | ${"STOCK".padRight(6)}',
    );
    print('-' * 75);

    for (int i = 0; i < products.length; i++) {
      var prod = products[i];
      int displayNo = i + 1;
      if (prod.id != null) menuIdToMongoIdMap[displayNo] = prod.id!;

      print(
        '${displayNo.toString().padRight(5)} | ${(prod.title ?? "Unknown").padRight(45)} | \$${(prod.price ?? 0.00).toStringAsFixed(2).padRight(9)} | ${prod.stockQuantity.toString().padRight(6)}',
      );
    }
    print('-' * 75);
  }

  /// Prompts select matrix categories based on underlying collection indices
  Future<String?> selectCategoryByNo() async {
    try {
      final response = await apiService.get(endpoint: '/categories');
      if (response != null && response is List) {
        if (response.isEmpty) {
          print('⚠️ No categories found.');
          return null;
        }

        menuIdToCategoryIdMap.clear();
        print('\n--- AVAILABLE CATEGORIES ---');
        for (int i = 0; i < response.length; i++) {
          var cat = response[i];
          int displayNo = i + 1;
          menuIdToCategoryIdMap[displayNo] = cat['_id'] ?? '';
          print('$displayNo. ${cat['name'] ?? "Unnamed Category"}');
        }
        int choice = InputValidator.readInt(
          prompt: 'Select Category Number (No): ',
          min: 1,
          max: response.length,
        );
        return menuIdToCategoryIdMap[choice];
      }
    } catch (e) {
      print('❌ Error pulling categories framework: $e');
    }
    return null;
  }

  /// Converts locally managed basket data maps into remote database order schemas
  Future<void> executeCheckoutOrder() async {
    final user = authService.currentUser;
    if (user == null || localCart.items.isEmpty) {
      print('❌ Processing Error: Invalid User or Empty Cart.');
      return;
    }

    print('\nSending order checkout arrays to MongoDB engine payloads...');
    List<Map<String, dynamic>> structuredItemsPayload = localCart.items.map((
      cartItem,
    ) {
      return {
        'product_id': cartItem.product.id,
        'quantity': cartItem.quantity.toInt(),
        'price_at_sale': cartItem.product.price ?? 0.00,
      };
    }).toList();

    Map<String, dynamic> orderPayload = {
      'sold_by': user.id,
      'total_price': localCart.calculateTotalPrice,
      'items': structuredItemsPayload,
    };

    try {
      final response = await apiService.post(
        endpoint: '/orders/checkout',
        body: orderPayload,
      );
      if (response != null) {
        print(
          '\n==============================================\n 🎉 ORDER SECURED AND WRITTEN SUCCESSFULLY!   \n==============================================',
        );
        localCart.clear();
      }
    } catch (e) {
      print('\n❌ Processing Failure: $e');
    }
  }

  /// Extracts comprehensive array list logs depicting ancient transaction receipt logs
  Future<void> viewAllOrdersHistory() async {
    print('\n--- PULLING ALL COMPLETED ORDER LOG RECORDS ---');
    try {
      final response = await apiService.get(endpoint: '/orders');
      if (response != null && response is List) {
        if (response.isEmpty) {
          print('No historical checkout entries found.');
          return;
        }

        for (var order in response) {
          if (order == null) continue;
          print(
            '\n📜 RECEIPT ID: ${order['_id'] ?? "Unknown ID"} | Cashier: ${order['sold_by'] != null ? order['sold_by']['username'] : 'System Base'}',
          );
          var items = order['items'] as List? ?? [];
          for (var item in items) {
            String pTitle = item['product_id'] != null
                ? (item['product_id']['title'] ?? 'Untitled Product')
                : 'Deleted Product';
            print(
              '   - $pTitle (Qty: ${item['quantity'] ?? 0}) @ \$${item['price_at_sale'] ?? 0.00} each',
            );
          }
          print(
            '• Paid Bill Value total: \$${(order['total_price'] as num? ?? 0.00).toDouble().toStringAsFixed(2)}',
          );
          print('--------------------------------------------------');
        }
      }
    } catch (e) {
      print('Failed to read response streams cleanly: $e');
    }
  }
}
