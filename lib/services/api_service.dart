import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 'http://localhost:3000/api' if testing purely on your machine.
  // (If testing using an Android emulator later, substitute with 'http://10.0.2.2:3000/api')
  final String baseUrl = 'http://localhost:3000/api';

  // Standard JSON request headers configuration
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Centralized GET request handler with built-in exception handling
  Future<dynamic> get({required String endpoint}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.get(url, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'GET', endpoint);
    }
  }

  /// Centralized POST request handler with required parameter tracking
  Future<dynamic> post({required String endpoint, required Map<String, dynamic> body}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body), // Encodes Dart Map collection into JSON string
      );
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'POST', endpoint);
    }
  }

  /// Centralized PUT request handler for structural data modifications or stock management
  Future<dynamic> put({required String endpoint, required Map<String, dynamic> body}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'PUT', endpoint);
    }
  }

  /// Centralized DELETE request handler
  Future<dynamic> delete({required String endpoint}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.delete(url, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e, 'DELETE', endpoint);
    }
  }

  /// Examines standard HTTP status codes and parses JSON payload
  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        // Decodes the raw response body string into parsed Maps or Lists dynamically
        return jsonDecode(response.body);
      case 400:
        throw Exception('Bad Request (400): ${jsonDecode(response.body)['message'] ?? 'Invalid input.'}');
      case 401:
        throw Exception('Unauthorized (401): Invalid credentials or access restriction.');
      case 404:
        throw Exception('Not Found (404): The requested resource could not be located.');
      case 500:
        throw Exception('Server Error (500): Connection to database/server failed.');
      default:
        throw Exception('Error (${response.statusCode}): Unexpected server transmission.');
    }
  }

  /// Formats explicit runtime failures cleanly in the console so your application doesn't crash
  void _handleNetworkError(Object error, String method, String endpoint) {
    print('\n[Network Log] Failure during $method sequence targeting: $endpoint');
    if (error is FormatException) {
      throw Exception('Data Processing Exception: Failed to read incoming server payload.');
    } else {
      throw Exception('Connection Refused: Confirm your Node.js server is actively running.');
    }
  }
}