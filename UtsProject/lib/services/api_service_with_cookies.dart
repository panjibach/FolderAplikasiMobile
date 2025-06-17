import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  
  // Cookie jar untuk menyimpan session cookies
  static final Map<String, String> _cookies = {};
  
  // HTTP client dengan cookie support
  static final http.Client _client = http.Client();

  // Helper method untuk menambahkan cookies ke request
  static Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    // Tambahkan cookies jika ada
    if (_cookies.isNotEmpty) {
      String cookieString = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
      headers['Cookie'] = cookieString;
      print('Sending cookies: $cookieString');
    }
    
    return headers;
  }

  // Helper method untuk menyimpan cookies dari response
  static void _saveCookies(http.Response response) {
    String? setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
      print('Received Set-Cookie: $setCookieHeader');
      
      // Parse multiple cookies
      List<String> cookies = setCookieHeader.split(',');
      for (String cookie in cookies) {
        List<String> parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          String name = parts[0].trim();
          String value = parts[1].trim();
          _cookies[name] = value;
          print('Saved cookie: $name=$value');
        }
      }
    }
  }

  // Login method dengan cookie handling
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('=== API LOGIN REQUEST ===');
      print('URL: $baseUrl/auth/login');
      print('Email: $email');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userEmail': email,
          'userPassword': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      // Save cookies dari response
      _saveCookies(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login successful: $data');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Register method
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      print('=== API REGISTER REQUEST ===');
      print('URL: $baseUrl/auth/register');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userName': name,
          'userEmail': email,
          'userPassword': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Register error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Logout method
  static Future<Map<String, dynamic>> logout() async {
    try {
      print('=== API LOGOUT REQUEST ===');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _getHeaders(),
      );

      print('Logout response: ${response.statusCode}');
      
      // Clear cookies setelah logout
      _cookies.clear();
      print('Cookies cleared');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Method untuk check session status
  static Future<Map<String, dynamic>> checkSessionStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/auth/session-status'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check session status');
      }
    } catch (e) {
      print('Session check error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generic GET method dengan cookies
  static Future<http.Response> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );
    _saveCookies(response);
    return response;
  }

  // Generic POST method dengan cookies
  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    _saveCookies(response);
    return response;
  }

  // Method untuk debug cookies
  static void printCookies() {
    print('Current cookies: $_cookies');
  }
}
