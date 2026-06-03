import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/services/api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  /// Fetches all inventory products from MongoDB
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _apiService.get(endpoint: '/product');

      if (response != null && response is List) {
        // Map list elements into structured objects using the product factory schema
        return response.map((jsonItem) => Product.fromJson(jsonItem)).toList();
      }
      return [];
    } catch (e) {
      print('\n[Product Fetch Error] Failed to retrieve products list: $e');
      return [];
    }
  }

  /// Looks up single product detail records matching a unique ID string
  Future<Product?> getProductDetails({required String id}) async {
    try {
      final response = await _apiService.get(endpoint: '/product/$id');
      if (response != null && response is Map<String, dynamic>) {
        return Product.fromJson(response);
      }
      return null;
    } catch (e) {
      print('\n[Details Error] ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    }
  }

  /// Creates a new product document inside the remote database (Admin Role feature)
  Future<bool> addProduct({
    required String title,
    required double price,
    required int stockQuantity,
    required String categoryId,
  }) async {
    try {
      final Map<String, dynamic> productPayload = {
        'title': title,
        'price': price,
        'stock_quantity': stockQuantity,
        'category_id': categoryId,
      };

      await _apiService.post(endpoint: '/product', body: productPayload);
      print(
        '\n--- Product "$title" added successfully to backend inventory! ---',
      );
      return true;
    } catch (e) {
      print(
        '\n[Add Product Error] ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  /// Updates existing records or custom inventory balances (Admin/Stock Management Feature)
  Future<bool> updateProduct({
    required String id,
    required Map<String, dynamic> updatedFields,
  }) async {
    try {
      await _apiService.put(endpoint: '/products/$id', body: updatedFields);
      print('\n--- Inventory specifications updated successfully! ---');
      return true;
    } catch (e) {
      print('\n[Update Error] ${e.toString().replaceAll('Exception: ', '')}');
      return false;
    }
  }

  /// Removes an item altogether from the active system data pool (Admin feature)
  Future<bool> deleteProduct({required String id}) async {
    try {
      await _apiService.delete(endpoint: '/products/$id');
      print(
        '\n--- Product document dropped successfully from system index. ---',
      );
      return true;
    } catch (e) {
      print('\n[Delete Error] ${e.toString().replaceAll('Exception: ', '')}');
      return false;
    }
  }

  /// Local Search implementation filtering an already pulled product collection list by title query
  List<Product> searchProducts({
    required List<Product> cachedList,
    required String query,
  }) {
    if (query.isEmpty) return cachedList;

    // Uses standard List/Map filter logic matching substrings case-insensitively
    return cachedList.where((product) {
      return product.title!.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
