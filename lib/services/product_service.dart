// lib/services/product_service.dart
import 'package:dart_pos_system/models/product.dart';
import 'package:dart_pos_system/services/api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  /// Fetches all active inventory lines and safely decodes identity headers
  Future<List<Product>> getAllProducts() async {
    try {
      // 1. Fire network request out to backend route endpoint
      final response = await _apiService.get(endpoint: '/product');

      if (response == null) {
        print('⚠️ Service Alert: Backend network stream returned null.');
        return [];
      }

      // 2. Normalize JSON enveloping (Handles cases where arrays are wrapped inside data blocks)
      dynamic targetList = response;
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          targetList = response['data'];
        } else if (response.containsKey('products')) {
          targetList = response['products'];
        }
      }

      // 3. Fallback extraction guard sequence
      if (targetList is List) {
        if (targetList.isEmpty) return [];
        return targetList.map((item) {
          if (item is Map<String, dynamic>) {
            // 🎯 FAIL-SAFE NORMALIZATION: If the backend sent 'id' instead of '_id',
            // merge it so Product.fromJson can map it smoothly.
            if (!item.containsKey('_id') && item.containsKey('id')) {
              item['_id'] = item['id'].toString();
            }

            return Product.fromJson(item);
          }
          return Product();
        }).toList();
      }

      print(
        '❌ Data Error: Expected a JSON array format but received: ${targetList.runtimeType}',
      );
    } catch (e) {
      print('❌ Product Service Pipe Crash Exception: $e');
    }
    return [];
  }

  /// Queries extended field metrics for a specific product item tracking key
  Future<Product?> getProductDetails({required String id}) async {
    try {
      final response = await _apiService.get(endpoint: '/product/$id');

      if (response != null && response is Map<String, dynamic>) {
        // Safe check for wrapper structures
        Map<String, dynamic> targetData = response;
        if (response.containsKey('data') &&
            response['data'] is Map<String, dynamic>) {
          targetData = response['data'];
        }

        if (!targetData.containsKey('_id') && targetData.containsKey('id')) {
          targetData['_id'] = targetData['id'].toString();
        }

        return Product.fromJson(targetData);
      }
    } catch (e) {
      print(
        '❌ Service Pipeline failed to extract single specification details: $e',
      );
    }
    return null;
  }

  /// Adds a new product record to the database
  Future<void> addProduct({
    required String title,
    required double price,
    required int stockQuantity,
    required String
    categoryId, // This receives the clean Hex ID from the view selection
  }) async {
    try {
      final payload = {
        'title': title,
        'price': price,
        'stock_quantity': stockQuantity,
        // 🎯 FIXED: Changed 'categoryId' to 'category_id' to match your Node.js model key
        'category_id': categoryId,
      };

      // Ensure endpoint matches your active Node.js router path (e.g., '/product' or '/api/products')
      final response = await _apiService.post(
        endpoint: '/product',
        body: payload,
      );
      if (response != null) {
        print('✅ Product "$title" successfully created in MongoDB.');
      }
    } catch (e) {
      print('❌ Product creation service pipeline failed: $e');
    }
  }

  /// Partially modifies fields on an existing product record
  Future<void> updateProduct({
    required String id,
    required Map<String, dynamic> updatedFields,
  }) async {
    try {
      final response = await _apiService.put(
        endpoint: '/product/$id',
        body: updatedFields,
      );
      if (response != null) {
        print('✅ Product modifications successfully saved to database.');
      }
    } catch (e) {
      print('❌ Product update service pipeline failed: $e');
    }
  }

  /// Permanently removes a product record from the database
  Future<void> deleteProduct({required String id}) async {
    try {
      final response = await _apiService.delete(endpoint: '/product/$id');
      if (response != null) {
        print('✅ Product safely purged from storage clusters.');
      }
    } catch (e) {
      print('❌ Product deletion service pipeline failed: $e');
    }
  }

  /// Searches a cached local collection list for matching keywords
  List<Product> searchProducts({
    required List<Product> cachedList,
    required String query,
  }) {
    if (query.trim().isEmpty) return cachedList;
    final normalizedQuery = query.toLowerCase();

    return cachedList.where((product) {
      final titleMatch = (product.title ?? '').toLowerCase().contains(
        normalizedQuery,
      );
      final categoryMatch = (product.categoryName ?? '').toLowerCase().contains(
        normalizedQuery,
      );
      return titleMatch || categoryMatch;
    }).toList();
  }
}
