// lib/helper/category_cache_helper.dart
import 'package:dart_pos_system/services/api_service.dart';

class CategoryCacheHelper {
  /// Pulls live response packages and syncs the reference memory map
  static Future<void> syncCache({
    required ApiService apiService,
    required Map<String, String> categoryIdToNameMap,
  }) async {
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
}