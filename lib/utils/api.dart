import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // ======================
  // BASE URL (Vercel backend)
  // ======================
  static const String baseUrl = 'https://distrohub-app-backend.vercel.app'; 


  // ======================
  // AUTH
  // ======================
 static Future<Map<String, dynamic>?> login({
  required String email,
  required String password,
}) async {
  try {
    final url = Uri.parse('$baseUrl/api/auth/login');

    print('┌─────────────────────────────── LOGIN REQUEST ───────────────────────────────┐');
    print('│ URL:          $url');
    print('│ Method:       POST');
    print('│ Headers:      ${{'Content-Type': 'application/json'}}');
    print('│ Body (raw):   ${jsonEncode({'email': email, 'password': '***'})}');
    print('│ Email used:   $email');
    print('└──────────────────────────────────────────────────────────────────────────────┘');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    print('┌─────────────────────────────── LOGIN RESPONSE ───────────────────────────────┐');
    print('│ Status code:  ${response.statusCode}');
    print('│ Headers:      ${response.headers}');
    print('│ Body (raw):   ${response.body}');
    print('└──────────────────────────────────────────────────────────────────────────────┘');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Login SUCCESS - Parsed data: $data');
      await saveSession(data['token'], data['user'] ?? {});
      return data;
    } else {
      print('Login FAILED - non-200 status');
      return null;
    }
  } catch (e, stack) {
    print('┌─────────────────────────────── LOGIN EXCEPTION ───────────────────────────────┐');
    print('│ Exception type:   ${e.runtimeType}');
    print('│ Exception:        $e');
    print('│ Stack trace:      $stack');
    print('└──────────────────────────────────────────────────────────────────────────────┘');
    return null;
  }
}

  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] ?? body;
      } else {
        print('Profile fetch failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Profile error: $e');
      return null;
    }
  }

  // ======================
  // BANK ACCOUNTS
  // ======================
  static Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bank-accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body['data'] ?? body['bank_accounts'] ?? []);
      }
      return [];
    } catch (e) {
      print('Bank accounts error: $e');
      return [];
    }
  }

  // ======================
  // PRODUCTS (Paged)
  // ======================
  static Future<Map<String, dynamic>> fetchProductsPaged({
    String search = '',
    int page = 1,
    int perPage = 8,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {'products': [], 'totalPages': 1};
    }

    final uri = Uri.parse('$baseUrl/api/products').replace(
      queryParameters: {
        'search': search.isNotEmpty ? search : null,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    try {
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
          'products': data['products'] ?? data['data'] ?? [],
          'totalPages': data['totalPages'] ??
                        data['last_page'] ??
                        data['meta']?['last_page'] ??
                        1,
        };
      }
      return {'products': [], 'totalPages': 1};
    } catch (e) {
      print('Products fetch error: $e');
      return {'products': [], 'totalPages': 1};
    }
  }

  // ======================
  // ORDERS
  // ======================
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Order created',
          'orderId': data['orderId'] ?? data['id'],
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      print('Order creation error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ======================
  // SESSION MANAGEMENT
  // ======================
  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
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
}