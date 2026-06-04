// lib/app.dart
import 'dart:io';
import 'package:dart_pos_system/enum/role.dart';
import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/models/cart.dart';
import 'package:dart_pos_system/models/order.dart';
import 'package:dart_pos_system/services/auth_service.dart';
import 'package:dart_pos_system/services/product_service.dart';
import 'package:dart_pos_system/services/api_service.dart';
import 'package:dart_pos_system/helper/input_validator.dart';
import 'package:dart_pos_system/views/admin_view.dart';
import 'package:dart_pos_system/views/sale_view.dart';

class App {
  // ✅ Exposed core services configuration context
  final AuthService authService = AuthService();
  final ProductService productService = ProductService();
  final ApiService apiService = ApiService();
  final Cart localCart = Cart();

  // ✅ Global state index reference tracking vectors
  final Map<int, String> menuIdToMongoIdMap = {};
  final Map<int, String> menuIdToCategoryIdMap = {};
  final Map<String, String> categoryIdToNameMap = {};

  /// System Runtime Execution Loop
  Future<void> run() async {
    print('====================================================');
    print('       WELCOME TO THE DART CONSOLE POS SYSTEM       ');
    print('====================================================');

    while (true) {
      final user = authService.currentUser;

      if (user == null) {
        await _showLoginMenu();
      } else if (user.role == Role.admin) {
        await AdminView.handleWorkflow(this);
      } else if (user.role == Role.sale) {
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
    menuIdToMongoIdMap.clear();
    menuIdToCategoryIdMap.clear();
    categoryIdToNameMap.clear();
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
    if (menuIdToMongoIdMap.isEmpty) {
      print('\n⚠️ Operational Block: Product map is currently empty.');
      print(
        '👉 Please select option [1] to pull a fresh product list stream first.',
      );
      return null;
    }

    int inputNo = InputValidator.readInt(
      prompt: 'Enter Product List Number (No): ',
      min: 1,
      max: menuIdToMongoIdMap.length,
    );

    String? realMongoId = menuIdToMongoIdMap[inputNo];
    if (realMongoId == null || realMongoId.isEmpty) {
      print(
        '❌ Execution Fault: Selection resolved to an empty or invalid reference key.',
      );
      return null;
    }

    return realMongoId;
  }

  /// Bridging hook allowing alternative UI perspectives to invoke the lookup matrix directly
  Future<void> searchProductsDirect() => searchProductsWorkflow();

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

  /// Fetches categorizations array from database endpoints for explicit selector prompts
  Future<String?> selectCategoryByNo() async {
    try {
      final response = await apiService.get(endpoint: '/category');
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
          menuIdToCategoryIdMap[displayNo] = (cat['_id'] ?? cat['id'] ?? '')
              .toString();
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

  /// Synchronizes the key-value map cache linking raw Hex strings to readable names
  Future<void> syncCategoryCache() async {
    try {
      final response = await apiService.get(endpoint: '/category');
      if (response != null && response is List) {
        categoryIdToNameMap.clear();
        for (var cat in response) {
          if (cat is Map && cat['name'] != null) {
            String? rawId = (cat['_id'] ?? cat['id'])?.toString();
            if (rawId != null) {
              String cleanKey = rawId.trim().toLowerCase();
              categoryIdToNameMap[cleanKey] = cat['name'].toString();
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Category Cache Sync failed slightly: $e');
    }
  }

  /// Pulls product inventory lists and renders a formatted table string layout
  Future<void> displayAllProducts() async {
    print('\n⏳ Synchronizing collection matrices...');
    await syncCategoryCache();

    List<Product> products = await productService.getAllProducts();
    if (products.isEmpty) {
      print('No products inside the MongoDB index.');
      return;
    }

    menuIdToMongoIdMap.clear();

    print('-' * 108);
    print(
      '${"NO".padRight(5)} | ${"PRODUCT NAME".padRight(40)} | ${"CATEGORY".padRight(20)} | ${"PRICE".padRight(12)} | ${"STOCK".padRight(6)}',
    );
    print('-' * 108);

    for (int i = 0; i < products.length; i++) {
      var prod = products[i];
      int displayNo = i + 1;
      if (prod.id != null) menuIdToMongoIdMap[displayNo] = prod.id!;

      String finalCategoryLabel = "Uncategorized";
      if (prod.categoryName != null && prod.categoryName!.isNotEmpty) {
        String lookupKey = prod.categoryName!.trim().toLowerCase();
        if (categoryIdToNameMap.containsKey(lookupKey)) {
          finalCategoryLabel = categoryIdToNameMap[lookupKey]!;
        } else {
          finalCategoryLabel = lookupKey.length > 12
              ? 'ID: ${lookupKey.substring(0, 6)}...'
              : lookupKey;
        }
      }

      print(
        '${displayNo.toString().padRight(5)} | ${(prod.title ?? "Unknown").padRight(40)} | ${finalCategoryLabel.padRight(20)} | \$${(prod.price ?? 0.00).toStringAsFixed(2).padRight(11)} | ${prod.stockQuantity.toString().padRight(6)}',
      );
    }
    print('-' * 108);
  }

  /// Displays item structural specs using list map index translations
  Future<void> viewProductDetails() async {
    String? realId = getMongoIdFromNoInput();
    if (realId == null) return;

    print('⏳ Querying product records from MongoDB...');
    var prod = await productService.getProductDetails(id: realId);

    if (prod != null) {
      String displayCategory = "Uncategorized";
      if (prod.categoryName != null && prod.categoryName!.isNotEmpty) {
        String lookupKey = prod.categoryName!.trim().toLowerCase();
        if (categoryIdToNameMap.containsKey(lookupKey)) {
          displayCategory = categoryIdToNameMap[lookupKey]!;
        } else {
          displayCategory = lookupKey;
        }
      }

      print('\n📦 PRODUCT SPECIFICATIONS DETAIL RECORD:');
      print('• Title Identity: ${prod.title ?? "Missing Name"}');
      print('• Price Matrix:   \$${(prod.price ?? 0.00).toStringAsFixed(2)}');
      print(
        '• Stock Balance:  ${(prod.stockQuantity ?? 0).toString()} items left',
      );
      print('• Category Group: $displayCategory');
    } else {
      print('\n❌ Error: Product details could not be parsed.');
    }
  }

  /// 🎯 MOVED HERE: Terminal logic routine evaluating text keyword matches inside collections
  Future<void> searchProductsWorkflow() async {
    String query = InputValidator.readString(
      prompt: 'Enter search keywords matching product names: ',
    );
    print('⏳ Querying inventory indices...');

    var databaseList = await productService.getAllProducts();
    var matches = productService.searchProducts(
      cachedList: databaseList,
      query: query,
    );

    print('\n🔎 MATCHES FOUND: (${matches.length})');
    for (var m in matches) {
      print(
        '-> Title: ${m.title ?? "No Name"} | Price: \$${(m.price ?? 0.00).toStringAsFixed(2)} | Stock: ${m.stockQuantity}',
      );
    }
  }

  /// Sends checkout transaction lists as payload streams to endpoint nodes
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
      // Send payload stream to backend checkout endpoint node
      final response = await apiService.post(
        endpoint: '/order/checkout',
        body: orderPayload,
      );

      if (response != null) {
        // Handle unexpected application error responses embedded within the status payload
        if (response is Map && response.containsKey('message')) {
          print('\n⚠️ CHECKOUT REJECTED BY SERVER:');
          print('👉 ${response['message']}');
          return;
        }

        print(
          '\n==============================================\n 🎉 ORDER SECURED AND WRITTEN SUCCESSFULLY!   \n==============================================',
        );
        localCart.clear();
      }
    } catch (e) {
      // 💡 Strips downstream strings to detect exact exception text sent back by ApiService
      String errorMsg = e.toString();

      if (errorMsg.contains('Insufficient stock') ||
          errorMsg.contains('invalid') ||
          errorMsg.contains('empty')) {
        print('\n⚠️ TRANSACTION FAILED (Stock/Validation Fault):');
        print('👉 ${errorMsg.replaceAll('Exception:', '').trim()}');
      } else {
        print('\n❌ Processing Failure: $e');
      }
    }
  }

  /// Iterates through customer receipt histories, mapping indices sequentially into structured tables
  Future<void> viewAllOrdersHistory() async {
    print('\n--- PULLING ALL COMPLETED ORDER LOG RECORDS ---');
    try {
      await syncCategoryCache();

      List<Product> allProducts = await productService.getAllProducts();
      Map<String, Product> productLookupMap = {};
      for (var prod in allProducts) {
        if (prod.id != null) {
          productLookupMap[prod.id!.trim().toLowerCase()] = prod;
        }
      }

      final response = await apiService.get(endpoint: '/order');
      if (response != null && response is List) {
        if (response.isEmpty) {
          print('No historical checkout entries found.');
          return;
        }

        List<Order> structuredOrders = response
            .map((jsonMap) => Order.fromJson(jsonMap as Map<String, dynamic>))
            .toList();

        int receiptNo = 1;

        for (var order in structuredOrders) {
          // 📊 RECEIPT CONTAINER HEADER (80 characters wide alignment box)
          print('\n┌' + '─' * 78 + '┐');
          print(
            '│ SALES RECEIPT '.padRight(35) +
                'No. ${receiptNo.toString().padRight(40)}│',
          );
          print('│ Cashier: ${(order.soldBy ?? "System Base").padRight(68)}│');
          print('├' + '─' * 78 + '┤');

          // Column Headers
          print(
            '│ ${"PRODUCT NAME".padRight(35)} | ${"CATEGORY".padRight(16)} | ${"QTY".padRight(4)} | ${"UNIT PRICE".padRight(12)} │',
          );
          print('├' + '─' * 78 + '┤');

          var items = order.orderItems ?? [];
          for (var item in items) {
            String pTitle = 'Unknown/Deleted Product';
            String pCategory = 'Uncategorized';

            if (item.productId != null) {
              String itemProdKey = item.productId!.trim().toLowerCase();

              if (productLookupMap.containsKey(itemProdKey)) {
                Product matchedProd = productLookupMap[itemProdKey]!;
                pTitle = matchedProd.title ?? 'Untitled Product';

                if (matchedProd.categoryName != null) {
                  String catKey = matchedProd.categoryName!
                      .trim()
                      .toLowerCase();
                  if (categoryIdToNameMap.containsKey(catKey)) {
                    pCategory = categoryIdToNameMap[catKey]!;
                  }
                }
              }
            }

            // Truncate ultra-long titles to keep table alignment intact
            if (pTitle.length > 35) {
              pTitle = pTitle.substring(0, 32) + '...';
            }
            if (pCategory.length > 16) {
              pCategory = pCategory.substring(0, 13) + '...';
            }

            double displayUnitPrice = (item.priceAtSale ?? 0.00);
            if ((item.quantity ?? 0) > 0) {
              displayUnitPrice = displayUnitPrice / item.quantity!;
            }

            // Print item row inside table borders
            String qtyStr = (item.quantity ?? 0).toString();
            String priceStr = '\$${displayUnitPrice.toStringAsFixed(2)}';

            print(
              '│ ${pTitle.padRight(35)} | ${pCategory.padRight(16)} | ${qtyStr.padRight(4)} | ${priceStr.padRight(12)} │',
            );
          }

          // Receipt Footer Summary
          print('├' + '─' * 78 + '┤');
          String totalLabel = 'TOTAL AMOUNT DUE:';
          String totalValStr =
              '\$${(order.totalPrice ?? 0.00).toStringAsFixed(2)}';

          print(
            '│ ' +
                totalLabel.padLeft(52) +
                ' | ' +
                totalValStr.padRight(22) +
                '│',
          );
          print('└' + '─' * 78 + '┘');

          receiptNo++; // Safely advance the menu index
        }
      }
    } catch (e) {
      print('Failed to read response streams cleanly: $e');
    }
  }
}
