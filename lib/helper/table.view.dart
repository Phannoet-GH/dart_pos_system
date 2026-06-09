// lib/helper/table_view.dart
import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/models/cart.dart';

class TableView {
  /// Renders a unified terminal grid matching live product inventory records
  static void renderProductTable({
    required List<Product> products,
    required Map<String, String> categoryIdToNameMap,
    required Cart localCart,
    required Map<int, String> menuIdToMongoIdMap,
  }) {
    menuIdToMongoIdMap.clear();

    const int totalWidth = 125;
    print('=' * totalWidth);
    print(
      '${"NO".padRight(5)} | ${"PRODUCT NAME".padRight(35)} | ${"CATEGORY".padRight(18)} | ${"PRICE".padRight(11)} | ${"CURRENT STOCK".padRight(15)} | ${"INCREMENT / STATUS"}',
    );
    print('=' * totalWidth);

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

      int cartQuantity = 0;
      final matchingCartItems = localCart.items.where(
        (item) => item.product.id == prod.id,
      );
      if (matchingCartItems.isNotEmpty) {
        cartQuantity = matchingCartItems.first.quantity.toInt();
      }

      int databaseStock = prod.stockQuantity ?? 0;
      int currentStock = databaseStock - cartQuantity;

      String titleStr = prod.title ?? "Unknown";
      if (titleStr.length > 35) titleStr = '${titleStr.substring(0, 32)}...';
      if (finalCategoryLabel.length > 18) {
        finalCategoryLabel = '${finalCategoryLabel.substring(0, 15)}...';
      }

      String trackingTag = "[ STABLE ]";
      if (currentStock <= 0) {
        trackingTag = "⚠️ OUT OF STOCK";
      } else if (currentStock < 10) {
        trackingTag = "📉 LOW STOCK (+$currentStock)";
      } else {
        trackingTag = "📦 AVAILABLE (+$currentStock)";
      }

      if (cartQuantity > 0) {
        trackingTag += " ($cartQuantity in active cart)";
      }

      print(
        '${displayNo.toString().padRight(5)} | ${titleStr.padRight(35)} | ${finalCategoryLabel.padRight(18)} | \$${(prod.price ?? 0.00).toStringAsFixed(2).padRight(10)} | ${currentStock.toString().padRight(15)} | $trackingTag',
      );
    }
    print('=' * totalWidth);
  }
  // Add this method inside lib/helper/table_view.dart

  /// Renders deep structural specifications for a single product inside a clean grid card
  static void renderProductDetailsCard(Product prod, String displayCategory) {
    const int boxWidth = 70;
    print('\n┌' + '─' * (boxWidth - 2) + '┐');
    print(
      '│ ' +
          '📦 PRODUCT SPECIFICATIONS DETAIL RECORD'.padRight(boxWidth - 4) +
          ' │',
    );
    print('├' + '─' * (boxWidth - 2) + '┤');

    String titleLabel = '• Title Identity : ';
    String titleContent = prod.title ?? "Missing Name";
    if (titleContent.length > 55)
      titleContent = '${titleContent.substring(0, 52)}...';
    print('│ ' + (titleLabel + titleContent).padRight(boxWidth - 4) + ' │');

    String priceLabel = '• Price Matrix   : ';
    String priceContent = '\$${(prod.price ?? 0.00).toStringAsFixed(2)}';
    print('│ ' + (priceLabel + priceContent).padRight(boxWidth - 4) + ' │');

    String stockLabel = '• Stock Balance  : ';
    String stockContent =
        '${(prod.stockQuantity ?? 0).toString()} items remaining';
    print('│ ' + (stockLabel + stockContent).padRight(boxWidth - 4) + ' │');

    String catLabel = '• Category Group : ';
    if (displayCategory.length > 55)
      displayCategory = '${displayCategory.substring(0, 52)}...';
    print('│ ' + (catLabel + displayCategory).padRight(boxWidth - 4) + ' │');

    print('└' + '─' * (boxWidth - 2) + '┘');
  }

  /// Renders keyword search match sets using the exact same wide grid alignments
  static void renderSearchTable({
    required List<Product> matches,
    required Map<String, String> categoryIdToNameMap,
    required Cart localCart,
  }) {
    if (matches.isEmpty) {
      print('\n🔎 No items matched your search criteria.');
      return;
    }

    const int totalWidth = 115;
    print('\n🔎 MATCHES FOUND: (${matches.length})');
    print('=' * totalWidth);
    print(
      '${"PRODUCT NAME".padRight(43)} | ${"CATEGORY".padRight(18)} | ${"PRICE".padRight(11)} | ${"CURRENT STOCK".padRight(15)} | ${"STATUS"}',
    );
    print('=' * totalWidth);

    for (var prod in matches) {
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

      int cartQuantity = 0;
      final matchingCartItems = localCart.items.where(
        (item) => item.product.id == prod.id,
      );
      if (matchingCartItems.isNotEmpty) {
        cartQuantity = matchingCartItems.first.quantity.toInt();
      }

      int databaseStock = prod.stockQuantity ?? 0;
      int currentStock = databaseStock - cartQuantity;

      String titleStr = prod.title ?? "Unknown";
      if (titleStr.length > 43) titleStr = '${titleStr.substring(0, 40)}...';
      if (finalCategoryLabel.length > 18) {
        finalCategoryLabel = '${finalCategoryLabel.substring(0, 15)}...';
      }

      String trackingTag = currentStock <= 0
          ? "⚠️ OUT"
          : (currentStock < 10 ? "📉 LOW" : "📦 OK");

      print(
        '${titleStr.padRight(43)} | ${finalCategoryLabel.padRight(18)} | \$${(prod.price ?? 0.00).toStringAsFixed(2).padRight(10)} | ${currentStock.toString().padRight(15)} | $trackingTag',
      );
    }
    print('=' * totalWidth);
  }

  /// Renders a dynamic prompt list for categories selection
  static void renderCategorySelectionList(List<dynamic> categories) {
    print('\n=== AVAILABLE CATEGORIES ===');
    for (int i = 0; i < categories.length; i++) {
      var cat = categories[i];
      int displayNo = i + 1;
      print('$displayNo. ${cat['name'] ?? "Unnamed Category"}');
    }
  }

  /// Renders the local temporary shopping cart using a clean boxed layout matrix
  static void renderCartTable(
    Cart localCart,
    Map<int, String> menuIdToMongoIdMap,
  ) {
    if (localCart.items.isEmpty) {
      print('\n🛒 Your operational session shopping cart is currently empty.');
      return;
    }

    const int boxWidth = 80;
    print('\n┌' + '─' * (boxWidth - 2) + '┐');
    print(
      '│ ' +
          'TEMPORARY SESSION SHOPPING CART ITEMS'.padRight(boxWidth - 4) +
          ' │',
    );
    print('├' + '─' * (boxWidth - 2) + '┤');

    print(
      '│ ${"NO".padRight(4)} | ${"PRODUCT NAME".padRight(35)} | ${"QTY".padRight(6)} | ${"SUBTOTAL".padRight(23)} │',
    );
    print('├' + '─' * (boxWidth - 2) + '┤');

    for (var item in localCart.items) {
      String displayNoStr = "?";
      if (menuIdToMongoIdMap.containsValue(item.product.id)) {
        displayNoStr = menuIdToMongoIdMap.entries
            .firstWhere((entry) => entry.value == item.product.id)
            .key
            .toString();
      }

      String titleStr = item.product.title ?? "Unknown Item";
      if (titleStr.length > 35) titleStr = '${titleStr.substring(0, 32)}...';

      String qtyStr = item.quantity.toInt().toString();
      String subTotalStr = '\$${item.subTotal.toStringAsFixed(2)}';

      print(
        '│ ${displayNoStr.padRight(4)} | ${titleStr.padRight(35)} | ${qtyStr.padRight(6)} | ${subTotalStr.padRight(23)} │',
      );
    }

    print('├' + '─' * (boxWidth - 2) + '┤');
    String totalLabel = 'TOTAL CART BALANCE VALUE:';
    String totalValStr =
        '\$${localCart.calculateTotalPrice.toStringAsFixed(2)}';

    print(
      '│ ' + totalLabel.padLeft(51) + ' | ' + totalValStr.padRight(22) + ' │',
    );
    print('└' + '─' * (boxWidth - 2) + '┘');
  }
}
