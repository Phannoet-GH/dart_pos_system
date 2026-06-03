import 'dart:io';
import '../helper/input_validator.dart';

class AdminView {
  /// Entry logic loop routing choices to specific management functions
  static Future<void> handleWorkflow(dynamic appScope) async {
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
        await appScope.displayAllProducts();
        break;
      case 2:
        await viewProductDetails(appScope);
        break;
      case 3:
        await addNewProduct(appScope);
        break;
      case 4:
        await updateProductInfo(appScope);
        break;
      case 5:
        await deleteProductRecord(appScope);
        break;
      case 6:
        await searchProductsWorkflow(appScope);
        break;
      case 7:
        await appScope.viewAllOrdersHistory();
        break;
      case 8:
        appScope.logoutSession();
        break;
    }
  }

  /// Interactive Form Function: View deep details of an item using its list number
  static Future<void> viewProductDetails(dynamic appScope) async {
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    print('⏳ Querying product records from MongoDB...');
    var prod = await appScope.productService.getProductDetails(id: realId);
    if (prod != null) {
      print('\n📦 PRODUCT SPECIFICATIONS DETAIL RECORD:');
      print('• Title Identity: ${prod.title ?? "Missing Name"}');
      print('• Price Matrix:   \$${(prod.price ?? 0.00).toStringAsFixed(2)}');
      print(
        '• Stock Balance:  ${(prod.stockQuantity ?? 0).toString()} items left',
      );
      print('• Category Group: ${prod.categoryName ?? "Uncategorized"}');
    } else {
      print('\n❌ Error: Product details could not be parsed.');
    }
  }

  /// Interactive Form Function: Prompts data inputs to register a brand new item
  static Future<void> addNewProduct(dynamic appScope) async {
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

    print('\nLoading categories database selection...');
    String? chosenCategoryId = await appScope.selectCategoryByNo();
    if (chosenCategoryId == null) {
      print(
        '❌ Product entry cancelled due to missing valid Category configuration.',
      );
      return;
    }

    print('⏳ Registering asset record inside system clusters...');
    await appScope.productService.addProduct(
      title: title,
      price: price,
      stockQuantity: stock,
      categoryId: chosenCategoryId,
    );
  }

  /// Interactive Form Function: Partially modify existing fields using inline prompt lines
  static Future<void> updateProductInfo(dynamic appScope) async {
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    print('\nLeave empty if you do not wish to adjust that specific field.');
    stdout.write('New Title (Press Enter to Skip): ');
    String? titleInput = stdin.readLineSync()?.trim();

    stdout.write('New Price (Press Enter to Skip): ');
    String? priceInput = stdin.readLineSync()?.trim();

    stdout.write('New Stock Level (Press Enter to Skip): ');
    String? stockInput = stdin.readLineSync()?.trim();

    Map<String, dynamic> updatedFields = {};
    if (titleInput != null && titleInput.isNotEmpty)
      updatedFields['title'] = titleInput;
    if (priceInput != null && priceInput.isNotEmpty) {
      updatedFields['price'] = double.tryParse(priceInput) ?? 0.00;
    }
    if (stockInput != null && stockInput.isNotEmpty) {
      updatedFields['stock_quantity'] = int.tryParse(stockInput) ?? 0;
    }

    stdout.write('Do you want to update the category? (y/N): ');
    String? changeCat = stdin.readLineSync()?.trim().toLowerCase();
    if (changeCat == 'y' || changeCat == 'yes') {
      String? updatedCatId = await appScope.selectCategoryByNo();
      if (updatedCatId != null) {
        updatedFields['categoryId'] = updatedCatId;
      }
    }

    if (updatedFields.isNotEmpty) {
      print('⏳ Pushing partial structural modification mappings to server...');
      await appScope.productService.updateProduct(
        id: realId,
        updatedFields: updatedFields,
      );
    } else {
      print('No changes submitted.');
    }
  }

  /// Interactive Form Function: Drop records permanently from database clusters
  static Future<void> deleteProductRecord(dynamic appScope) async {
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    bool confirm = InputValidator.readConfirmation(
      prompt: '⚠️ Are you certain you want to drop this record?',
    );
    if (confirm) {
      print('⏳ Dropping resource indexes from document clusters...');
      await appScope.productService.deleteProduct(id: realId);
    }
  }

  /// Terminal Presentation Function: Searches the local structural array list matches
  static Future<void> searchProductsWorkflow(dynamic appScope) async {
    String query = InputValidator.readString(
      prompt: 'Enter search keywords matching product names: ',
    );
    var databaseList = await appScope.productService.getAllProducts();
    var matches = appScope.productService.searchProducts(
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
}
