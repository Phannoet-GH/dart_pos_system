// lib/helper/menu_selector.dart
import 'input_validator.dart';

class MenuSelector {
  /// Prompts for index list items and shifts the numerical reference back to raw Mongo Strings
  static String? getMongoIdFromMap(Map<int, String> menuIdToMongoIdMap) {
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
}
