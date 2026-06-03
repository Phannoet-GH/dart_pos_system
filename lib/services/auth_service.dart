import 'package:dart_pos_system/models/user.dart';
import 'package:dart_pos_system/services/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Keeps track of the currently logged-in user session in memory
  User? _currentUser;

  // Getter to check the active user profile across your console application
  User? get currentUser => _currentUser;

  /// Authenticates user credentials via the backend API
  /// Uses required named parameters as demanded by the project guidelines
  Future<User?> login({
    required String username,
    required String password,
  }) async {
    try {
      // Define payload parameters mapping
      final Map<String, dynamic> loginData = {
        'username': username,
        'password': password,
      };

      // Execute POST request via base network engine
      final response = await _apiService.post(
        endpoint: '/auth/login',
        body: loginData,
      );

      if (response != null && response is Map<String, dynamic>) {
        // Instantiate the User model utilizing its Factory Constructor
        _currentUser = User.fromJson(response);
        print(
          '\n--- Login Successful! Welcome, ${_currentUser!.username} [Role: ${_currentUser!.role}] ---',
        );
        return _currentUser;
      }
      return null;
    } catch (e) {
      // Catch exceptions gracefully to keep the terminal operational
      print('\n[Login Error] ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    }
  }

  /// Clears the operational runtime session user state
  void logout() {
    if (_currentUser != null) {
      print('\n--- User ${_currentUser!.username} has logged out safely. ---');
      _currentUser = null;
    } else {
      print('\n[Session Notice] No active user session detected.');
    }
  }
}
