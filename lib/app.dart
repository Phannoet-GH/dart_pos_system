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
import 'package:dart_pos_system/helper/menu_selector.dart';
import 'package:dart_pos_system/helper/category_cache_helper.dart';
import 'package:dart_pos_system/views/admin_view.dart';
import 'package:dart_pos_system/views/sale_view.dart';
import 'package:dart_pos_system/helper/table.view.dart';

class App {
  final AuthService authService = AuthService();
  final ProductService productService = ProductService();
  final ApiService apiService = ApiService();
  final Cart localCart = Cart();

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

  /// Wrapper linking components cleanly back to the modular MenuSelector class
  String? getMongoIdFromNoInput() {
    return MenuSelector.getMongoIdFromMap(menuIdToMongoIdMap);
  }

  /// Bridging hook allowing alternative UI perspectives to invoke the lookup matrix directly
  Future<void> searchProductsDirect() => searchProductsWorkflow();

  // =========================================================================
  // BACKEND API LOGIC PIPELINES
  // =========================================================================

  /// Handles input credential verification requests
  Future<void> _showLoginMenu() async {
    print('\n=== SYSTEM AUTHENTICATION ===');
    print('1. Login to POS');
    print('2. Exit Application');
    print('=============================');
    int choice = InputValidator.readInt(
      prompt: 'Select an option : ',
      min: 1,
      max: 2,
    );

    if (choice == 2) {
      print('\nGoodbye!');
      exit(0);
    }
    print('\n=== LOGIN TO POS SYSTEM ===');
    String username = InputValidator.readString(prompt: 'Username: ');
    String password = InputValidator.readPassword(prompt: 'Password: ');
    print("=============================");
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

        // Render UI table list using helper
        TableView.renderCategorySelectionList(response);

        for (int i = 0; i < response.length; i++) {
          var cat = response[i];
          int displayNo = i + 1;
          menuIdToCategoryIdMap[displayNo] = (cat['_id'] ?? cat['id'] ?? '')
              .toString();
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
    await CategoryCacheHelper.syncCache(
      apiService: apiService,
      categoryIdToNameMap: categoryIdToNameMap,
    );
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

    TableView.renderProductTable(
      products: products,
      categoryIdToNameMap: categoryIdToNameMap,
      localCart: localCart,
      menuIdToMongoIdMap: menuIdToMongoIdMap,
    );
  }

  /// Displays item structural specs using list map index translations
  Future<void> viewProductDetails() async {
    String? realId = getMongoIdFromNoInput();
    if (realId == null) return;

    print('⏳ Querying product records from MongoDB...');
    var prod = await productService.getProductDetails(id: realId);

    if (prod != null) {
      String displayCategory = "Uncategorized";
      if (prod.categoryName != null &&
          prod.categoryName!.toString().isNotEmpty) {
        String lookupKey = prod.categoryName!.toString().trim().toLowerCase();
        if (categoryIdToNameMap.containsKey(lookupKey)) {
          displayCategory = categoryIdToNameMap[lookupKey]!;
        } else {
          displayCategory = lookupKey;
        }
      }

      TableView.renderProductDetailsCard(prod, displayCategory);
    } else {
      print('\n❌ Error: Product details could not be parsed or found.');
    }
  }

  /// Terminal logic routine evaluating text keyword matches inside collections
  Future<void> searchProductsWorkflow() async {
    String query = InputValidator.readString(
      prompt: 'Enter search keywords matching product names: ',
    );
    print('⏳ Querying inventory indices...');

    await syncCategoryCache();
    var databaseList = await productService.getAllProducts();
    var matches = productService.searchProducts(
      cachedList: databaseList,
      query: query,
    );

    TableView.renderSearchTable(
      matches: matches,
      categoryIdToNameMap: categoryIdToNameMap,
      localCart: localCart,
    );
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
      final response = await apiService.post(
        endpoint: '/order/checkout',
        body: orderPayload,
      );

      if (response != null) {
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

  /// Iterates through customer receipt histories, mapping indices sequentially into a clean summary list
  Future<void> viewAllOrdersHistory() async {
    print('\n========================================================');
    print('          COMPLETED TRANSACTION HISTORY LOGS            ');
    print('========================================================');
    try {
      final response = await apiService.get(endpoint: '/order');
      if (response == null || response is! List || response.isEmpty) {
        print('No historical checkout entries found.');
        return;
      }

      List<Order> structuredOrders = response
          .map((jsonMap) => Order.fromJson(jsonMap as Map<String, dynamic>))
          .toList();

      print('┌─────────────┬────────────────────────────────┬──────────────┐');
      print('│ RECEIPT NO. │ CASHIER / SOLD BY              │ TOTAL AMOUNT │');
      print('├─────────────┼────────────────────────────────┼──────────────┤');

      int receiptNo = 1;
      for (var order in structuredOrders) {
        String receiptStr = '#${receiptNo.toString()}';
        String cashierStr = (order.soldBy ?? "System Base");
        if (cashierStr.length > 30) {
          cashierStr = '${cashierStr.substring(0, 27)}...';
        }
        String totalStr = '\$${(order.totalPrice ?? 0.00).toStringAsFixed(2)}';

        print(
          '│ ${receiptStr.padRight(11)} │ ${cashierStr.padRight(30)} │ ${totalStr.padLeft(12)} │',
        );
        receiptNo++;
      }
      print('└─────────────┴────────────────────────────────┴──────────────┘');
      print('💡 Tip: To view exact itemizations for a sale, use Option 12.');
    } catch (e) {
      print('Failed to read transaction log streams: $e');
    }
  }

  /// Pulls orders from API and filters out a single targeted receipt profile
  Future<void> viewSpecificReceiptWorkflow() async {
    print('\n=== VIEW SPECIFIC RECEIPT DETAILS ===');
    try {
      // 1. Fetch orders data baseline
      final response = await apiService.get(endpoint: '/order');
      if (response == null || response is! List || response.isEmpty) {
        print('No historical checkout entries found to view.');
        return;
      }

      List<Order> structuredOrders = response
          .map((jsonMap) => Order.fromJson(jsonMap as Map<String, dynamic>))
          .toList();

      // 2. Safely capture the user input choice boundary
      int targetReceiptNo = InputValidator.readInt(
        prompt:
            'Enter the Receipt No to open in detail (1 to ${structuredOrders.length}): ',
        min: 1,
        max: structuredOrders.length,
      );

      Order order = structuredOrders[targetReceiptNo - 1];

      // 3. Fire structural caches and product lookups concurrently
      print('⏳ Loading detailed collection maps from MongoDB...');
      await syncCategoryCache();
      List<Product> allProducts = await productService.getAllProducts();

      Map<String, Product> productLookupMap = {};
      for (var prod in allProducts) {
        if (prod.id != null) {
          productLookupMap[prod.id!.trim().toLowerCase()] = prod;
        }
      }

      // 4. Print structured receipt layout
      print('\n┌' + '─' * 78 + '┐');
      print(
        '│ ' +
            'SALES RECEIPT '.padRight(34) +
            'No. ${targetReceiptNo.toString().padRight(38)} │',
      );
      print('│ Cashier: ${(order.soldBy ?? "System Base").padRight(67)} │');
      print('├' + '─' * 78 + '┤');
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

            if (matchedProd.categoryName != null &&
                matchedProd.categoryName!.toString().isNotEmpty) {
              String catKey = matchedProd.categoryName!
                  .toString()
                  .trim()
                  .toLowerCase();
              if (categoryIdToNameMap.containsKey(catKey)) {
                pCategory = categoryIdToNameMap[catKey]!;
              } else {
                pCategory = catKey;
              }
            }
          }
        }

        if (pTitle.length > 35) pTitle = '${pTitle.substring(0, 32)}...';
        if (pCategory.length > 16)
          pCategory = '${pCategory.substring(0, 13)}...';

        double displayUnitPrice = (item.priceAtSale ?? 0.00);
        String qtyStr = (item.quantity ?? 0).toString();
        String priceStr = '\$${displayUnitPrice.toStringAsFixed(2)}';

        print(
          '│ ${pTitle.padRight(35)} | ${pCategory.padRight(16)} | ${qtyStr.padRight(4)} | ${priceStr.padRight(12)} │',
        );
      }

      print('├' + '─' * 78 + '┤');
      String totalLabel = 'TOTAL AMOUNT DUE:';
      String totalValStr = '\$${(order.totalPrice ?? 0.00).toStringAsFixed(2)}';

      print(
        '│ ' + totalLabel.padLeft(51) + ' | ' + totalValStr.padRight(22) + ' │',
      );
      print('└' + '─' * 78 + '┘\n');
    } catch (e) {
      print('Failed to load specific receipt details: $e');
    }
  }
}
