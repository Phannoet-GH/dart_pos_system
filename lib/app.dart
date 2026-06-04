// lib/app.dart
import 'dart:io';
import 'package:dart_pos_system/enum/role.dart';
import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/models/cart.dart';
import 'package:dart_pos_system/services/auth_service.dart';
import 'package:dart_pos_system/services/product_service.dart';
import 'package:dart_pos_system/services/api_service.dart';
import 'package:dart_pos_system/helper/input_validator.dart';
import 'package:dart_pos_system/views/admin_view.dart';
import 'package:dart_pos_system/views/sale_view.dart';
import 'package:dart_pos_system/models/order.dart';

class App {
  // ✅ Publicly exposed infrastructure instances for the UI presentation layer
  final AuthService authService = AuthService();
  final ProductService productService = ProductService();
  final ApiService apiService = ApiService();
  final Cart localCart = Cart();

  // ✅ FIXED: Removed underscores (_) to make caches public. View layers can now read maps safely!
  final Map<int, String> menuIdToMongoIdMap = {};
  final Map<int, String> menuIdToCategoryIdMap = {};

  // 🎯 NEW: Global category dictionary mapping raw 24-character backend Hex IDs to clear titles
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
    menuIdToMongoIdMap
        .clear(); // 🧹 Wipe internal maps clean to prevent leakage
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

  Future<String?> selectCategoryByNo() async {
    try {
      // 🎯 FIXED: Changed from '/categories' to '/category' here too
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
          // Accept both '_id' or 'id' depending on backend transformation layers
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

  /// Fetches all categories from the backend and maps them by id string
  Future<void> syncCategoryCache() async {
    try {
      // 🎯 Match this endpoint parameter string exactly with your backend prefix
      final response = await apiService.get(endpoint: '/category');

      if (response != null && response is List) {
        categoryIdToNameMap.clear();
        for (var cat in response) {
          if (cat is Map && cat['name'] != null) {
            // 🎯 Read '_id' or 'id' from your Mongoose Category model safely
            String? rawId = (cat['_id'] ?? cat['id'])?.toString();

            if (rawId != null) {
              // Standardize lowercase and trim string spacing to prevent mapping mismatches
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

  /// Synchronizes active payload inventory structures from remote database clusters
  Future<void> displayAllProducts() async {
    print('\n⏳ Synchronizing collection matrices...');

    // Step 1: Populate the look-up table map before rendering rows
    await syncCategoryCache();

    // Step 2: Fetch products list
    List<Product> products = await productService.getAllProducts();
    if (products.isEmpty) {
      print('No products inside the MongoDB index.');
      return;
    }

    menuIdToMongoIdMap.clear();

    // 📊 TABLE HEADER FOR TERMINAL: Properly padded space alignment mapping out to 108 characters wide
    print('-' * 108);
    print(
      '${"NO".padRight(5)} | ${"PRODUCT NAME".padRight(40)} | ${"CATEGORY".padRight(20)} | ${"PRICE".padRight(12)} | ${"STOCK".padRight(6)}',
    );
    print('-' * 108);

    for (int i = 0; i < products.length; i++) {
      var prod = products[i];
      int displayNo = i + 1;
      if (prod.id != null) menuIdToMongoIdMap[displayNo] = prod.id!;

      // 🎯 Step 3: Parse and substitute backend raw string Hex IDs with cached titles
      String finalCategoryLabel = "Uncategorized";

      if (prod.categoryName != null && prod.categoryName!.isNotEmpty) {
        // Normalize the product's category reference to match our cache keys
        String lookupKey = prod.categoryName!.trim().toLowerCase();

        if (categoryIdToNameMap.containsKey(lookupKey)) {
          finalCategoryLabel = categoryIdToNameMap[lookupKey]!;
        } else {
          // If it still can't find a direct match, show a clean shortened ID instead of the long hex string
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
  // lib/app.dart (Inside the App class)

  // =========================================================================
  // BACKEND API LOGIC PIPELINES
  // =========================================================================

  /// Interactive Form Function: View deep details of an item using its list number
  Future<void> viewProductDetails() async {
    // 1. Ask the user for a list number and translate it into a true MongoDB hex string ID
    String? realId = getMongoIdFromNoInput();
    if (realId == null) return;

    print('⏳ Querying product records from MongoDB...');

    // 2. Fetch the deep specifications object data out of the service layer
    var prod = await productService.getProductDetails(id: realId);

    if (prod != null) {
      String displayCategory = "Uncategorized";

      // 3. Resolve the Hex ID out of the local cache dictionary map safely
      if (prod.categoryName != null && prod.categoryName!.isNotEmpty) {
        String lookupKey = prod.categoryName!.trim().toLowerCase();

        if (categoryIdToNameMap.containsKey(lookupKey)) {
          displayCategory = categoryIdToNameMap[lookupKey]!;
        } else {
          // Fallback condition if the cache key isn't loaded
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

  // ... rest of your existing app.dart methods like displayAllProducts() or executeCheckoutOrder()

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
        endpoint: '/order/checkout',
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
  // lib/app.dart

  /// Extracts comprehensive array list logs depicting historical transaction receipt logs
  Future<void> viewAllOrdersHistory() async {
    print('\n--- PULLING ALL COMPLETED ORDER LOG RECORDS ---');
    try {
      // Step 1: Ensure category cache dictionary is synced
      await syncCategoryCache();

      // Pull all products so we can look up titles and categories by their raw productId
      List<Product> allProducts = await productService.getAllProducts();

      // Build an optimization lookup map for products: productId -> Product Object
      Map<String, Product> productLookupMap = {};
      for (var prod in allProducts) {
        if (prod.id != null) {
          productLookupMap[prod.id!.trim().toLowerCase()] = prod;
        }
      }

      // Step 2: Fetch the raw array from your endpoint
      final response = await apiService.get(endpoint: '/order');

      if (response != null && response is List) {
        if (response.isEmpty) {
          print('No historical checkout entries found.');
          return;
        }

        // Step 3: Parse the raw network list into strongly-typed Order instances
        List<Order> structuredOrders = response
            .map((jsonMap) => Order.fromJson(jsonMap as Map<String, dynamic>))
            .toList();

        // 🎯 FIX: Initialize a simple index counter for the terminal display
        int receiptNo = 1;

        for (var order in structuredOrders) {
          // 🎯 FIX: Display 'No. X' instead of the long order.id hex string!
          print(
            '\n📜 RECEIPT No. ${receiptNo++} | Cashier: ${order.soldBy ?? "System Base"}',
          );

          var items = order.orderItems ?? [];
          for (var item in items) {
            String pTitle = 'Unknown/Deleted Product';
            String pCategory = 'Uncategorized';

            // Cross-reference item.productId against our product tracker matrix
            if (item.productId != null) {
              String itemProdKey = item.productId!.trim().toLowerCase();

              if (productLookupMap.containsKey(itemProdKey)) {
                Product matchedProd = productLookupMap[itemProdKey]!;
                pTitle = matchedProd.title ?? 'Untitled Product';

                // Extract category name using the dictionary
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

            // Calculate true unit price for the display string layout
            double displayUnitPrice = (item.priceAtSale ?? 0.00);
            if ((item.quantity ?? 0) > 0) {
              displayUnitPrice = displayUnitPrice / item.quantity!;
            }

            print(
              '   - $pTitle [$pCategory] (Qty: ${item.quantity ?? 0}) @ \$${displayUnitPrice.toStringAsFixed(2)} each',
            );
          }

          print(
            '• Paid Bill Value total: \$${(order.totalPrice ?? 0.00).toStringAsFixed(2)}',
          );
          print('--------------------------------------------------');
        }
      }
    } catch (e) {
      print('Failed to read response streams cleanly: $e');
    }
  }
}
