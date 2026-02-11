import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // ======================
  // BASE URL
  // ======================
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api'; // Android emulator
    } else {
      return 'http://localhost:5000/api'; // iOS, desktop, web
    }
  }

  // ======================
  // AUTH
  // ======================
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Backend returns { success, message, data: {...} }
      // Extract the data object which contains user info
      return body['data'] ?? body;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bank-accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body['bank_accounts'] ?? [];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching bank accounts: $e');
      return [];
    }
  }

  // ======================
  // PRODUCT SECTION
  // ======================
  static Future<Map<String, dynamic>> fetchProductsPaged({
    String search = '',
    int page = 1,
    int perPage = 8,  // default to 8 items per page
  }) async {
    final token = await getToken();
    if (token == null) {
      return {
        'products': [],
        'totalPages': 1,
      };
    }

    final uri = Uri.parse('$baseUrl/products').replace(
      queryParameters: {
        'search': search.isNotEmpty ? search : null,
        'page': page.toString(),
        'per_page': perPage.toString(),  // most common name
        // If your backend uses different name, change to:
        // 'limit': perPage.toString(),
        // 'size': perPage.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'products': data['products'] ?? data['data'] ?? data['items'] ?? [],
        'totalPages': data['totalPages'] ??
                      data['last_page'] ??
                      data['pages'] ??
                      data['meta']?['last_page'] ??
                      1,
      };
    } else {
      throw Exception('Failed to load products: ${response.statusCode} - ${response.body}');
    }
  }

  // ======================
  // SESSION MANAGEMENT
  // ======================
  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ======================
  // ORDERS
  // ======================
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Order created successfully',
          'orderId': data['orderId'] ?? data['id'],
          'data': data,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Get user's order history
  static Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? [];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching order history: $e');
      return [];
    }
  }

  // Get order details with items
  static Future<Map<String, dynamic>?> getOrderDetails(String orderNo) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders-history/$orderNo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] ?? body;
      }
      return null;
    } catch (e) {
      print('Error fetching order details: $e');
      return null;
    }
  }

  // Optional: old non-paginated method – keep commented or remove
  /*
  static Future<List<dynamic>> fetchProducts() async {
    final token = await getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['products'] ?? [];
    }

    return [];
  }
  */
}