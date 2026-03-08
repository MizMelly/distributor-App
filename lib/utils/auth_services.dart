import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ======================
  // BASE URL - Live Vercel backend
  // ======================
  static const String baseUrl = 'https://distrohub-app-backend.vercel.app';

  // For local development/testing (comment out in production)
  // static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator only
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator or desktop

  // ======================
  // LOGIN
  // ======================
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');

      print('LOGIN REQUEST → $url');
      print('Body: {"email": "$email", "password": "***"}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('LOGIN RESPONSE → ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save token & user
        await saveSession(data['token'], data['user'] ?? {});
        return data;
      } else {
        print('Login failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('LOGIN EXCEPTION: $e');
      print('Stack: $stack');
      return null;
    }
  }

  // ======================
  // SAVE SESSION
  // ======================
  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
    print('Session saved: token = ${token.substring(0, 10)}...');
  }

  // ======================
  // GET TOKEN
  // ======================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved token: ${token != null ? "exists" : "missing"}');
    return token;
  }

  // ======================
  // LOGOUT
  // ======================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    print('User logged out - session cleared');
  }
}