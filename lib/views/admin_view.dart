// lib/views/admin_view.dart
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
    print('4. Update Product Details (API)');
    print('5. Manage Inventory Stock (API)');
    print('6. Delete Product (API)');
    print('7. Search Products (Local)');
    print('8. View All Transaction Orders (API)');
    print('9. Logout Session');
    print('====================================');

    int choice = InputValidator.readInt(
      prompt: 'Choose an operational index (1-9): ',
      min: 1,
      max: 9,
    );

    switch (choice) {
      case 1:
        await appScope.displayAllProducts();
        break;
      case 2:
        // 🎯 FIXED: Now routes straight into the backend pipeline method on your app core shell
        await appScope.viewProductDetails();
        break;
      case 3:
        await addNewProduct(appScope);
        break;
      case 4:
        await updateProductFields(appScope);
        break;
      case 5:
        await manageStockLevel(appScope);
        break;
      case 6:
        await deleteProductRecord(appScope);
        break;
      case 7:
        await searchProductsWorkflow(appScope);
        break;
      case 8:
        await appScope.viewAllOrdersHistory();
        break;
      case 9:
        appScope.logoutSession();
        break;
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

  /// Focused purely on details customization (Title, Price, Category)
  static Future<void> updateProductFields(dynamic appScope) async {
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    print('\nLeave empty if you do not wish to adjust that specific field.');
    stdout.write('New Title (Press Enter to Skip): ');
    String? titleInput = stdin.readLineSync()?.trim();

    stdout.write('New Price (Press Enter to Skip): ');
    String? priceInput = stdin.readLineSync()?.trim();

    Map<String, dynamic> updatedFields = {};
    if (titleInput != null && titleInput.isNotEmpty) {
      updatedFields['title'] = titleInput;
    }
    if (priceInput != null && priceInput.isNotEmpty) {
      updatedFields['price'] = double.tryParse(priceInput) ?? 0.00;
    }

    stdout.write('Do you want to update the category? (y/N): ');
    String? changeCat = stdin.readLineSync()?.trim().toLowerCase();
    if (changeCat == 'y' || changeCat == 'yes') {
      String? updatedCatId = await appScope.selectCategoryByNo();
      if (updatedCatId != null) {
        updatedFields['category_id'] = updatedCatId;
      }
    }

    if (updatedFields.isNotEmpty) {
      print('⏳ Pushing description adjustments to database server...');
      await appScope.productService.updateProduct(
        id: realId,
        updatedFields: updatedFields,
      );
    } else {
      print('No change updates submitted.');
    }
  }

  /// Dedicated specifically to Stock Audits & Cargo Arrivals
  static Future<void> manageStockLevel(dynamic appScope) async {
    String? realId = appScope.getMongoIdFromNoInput();
    if (realId == null) return;

    print('\n--- INVENTORY STOCK MANAGEMENT ---');
    print('1. Add New Shipment (Increase Stock)');
    print('2. Manual Stock Adjustment Correction (Set Absolute Level)');
    int stockMode = InputValidator.readInt(
      prompt: 'Select operation type (1-2): ',
      min: 1,
      max: 2,
    );

    Map<String, dynamic> updatedFields = {};

    if (stockMode == 1) {
      int incomingQty = InputValidator.readInt(
        prompt: 'Enter quantity received from supplier: ',
        min: 1,
      );
      updatedFields['stock_increment'] = incomingQty;
    } else {
      int absoluteQty = InputValidator.readInt(
        prompt: 'Enter actual real stock level sitting on shelf: ',
        min: 0,
      );
      updatedFields['stock_quantity'] = absoluteQty;
    }

    print('⏳ Adjusting stock pool matrix records...');
    await appScope.productService.updateProduct(
      id: realId,
      updatedFields: updatedFields,
    );
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
