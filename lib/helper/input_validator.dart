import 'dart:io';

class InputValidator {
  /// Captures a non-empty string from the terminal.
  /// Prevents the user from simply hitting 'Enter' to submit blank inputs.
  static String readString({required String prompt}) {
    while (true) {
      stdout.write(prompt);
      String? input = stdin.readLineSync();

      if (input != null && input.trim().isNotEmpty) {
        return input.trim();
      }
      print('❌ Error: Input cannot be empty. Please try again.');
    }
  }

  /// Captures a secure password string without trimming leading/trailing spaces
  static String readPassword({required String prompt}) {
    while (true) {
      stdout.write(prompt);
      String? input = stdin.readLineSync();

      if (input != null && input.isNotEmpty) {
        return input;
      }
      print('❌ Error: Password cannot be empty.');
    }
  }

  /// Captures a valid Integer number (e.g., for Menu Choices, Quantities, and Stock balances).
  /// Implements try-catch parsing blocks to prevent system crashes on alphabet inputs.
  static int readInt({required String prompt, int? min, int? max}) {
    while (true) {
      stdout.write(prompt);
      String? input = stdin.readLineSync();

      if (input == null || input.trim().isEmpty) {
        print('❌ Error: Please enter a valid whole number.');
        continue;
      }

      try {
        int value = int.parse(input.trim());

        // Validate range bounds if they are specified
        if (min != null && value < min) {
          print('❌ Error: Number must be at least $min.');
          continue;
        }
        if (max != null && value > max) {
          print('❌ Error: Number cannot exceed $max.');
          continue;
        }

        return value;
      } on FormatException {
        print(
          '❌ Error: Invalid format. Please enter numbers only (no letters or symbols).',
        );
      }
    }
  }

  /// Captures a valid Double precision floating point number (e.g., for Product Prices).
  static double readDouble({required String prompt, double? min}) {
    while (true) {
      stdout.write(prompt);
      String? input = stdin.readLineSync();

      if (input == null || input.trim().isEmpty) {
        print('❌ Error: Please enter a valid decimal price.');
        continue;
      }

      try {
        double value = double.parse(input.trim());

        if (min != null && value < min) {
          print('❌ Error: Value must be at least \$${min.toStringAsFixed(2)}.');
          continue;
        }

        return value;
      } on FormatException {
        print(
          '❌ Error: Invalid format. Please enter a valid price (e.g., 1.50 or 12).',
        );
      }
    }
  }

  /// Displays a customizable confirmation prompt returning true for 'y' and false for 'n'.
  static bool readConfirmation({required String prompt}) {
    while (true) {
      stdout.write('$prompt (y/n): ');
      String? input = stdin.readLineSync()?.trim().toLowerCase();

      if (input == 'y' || input == 'yes') return true;
      if (input == 'n' || input == 'no') return false;

      print('❌ Error: Please enter "y" for Yes or "n" for No.');
    }
  }
}
