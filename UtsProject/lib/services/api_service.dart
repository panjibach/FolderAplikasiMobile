import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart' as CategoryModel;
import '../models/transaction.dart';
import '../models/transaction_summary.dart';
import '../models/dashboard.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8081/api'; // For Android Emulator
  // static const String baseUrl = 'http://localhost:8081/api'; // For iOS Simulator
  // static const String baseUrl = 'http://YOUR_IP_ADDRESS:8081/api'; // For Physical Device

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _getHeaders({bool requiresAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    return headers;
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========== AUTH METHODS (UPDATED FOR SPRING BOOT BACKEND) ==========
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'), // Updated endpoint
        headers: _getHeaders(),
        body: jsonEncode({
          'userEmail': email,     // Updated field name
          'userPassword': password, // Updated field name
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw ApiException(
          data['error'] ?? 'Login failed',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on HttpException {
      throw ApiException('Server error', 500);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'), // Updated endpoint
        headers: _getHeaders(),
        body: jsonEncode({
          'userName': name,        // Updated field name
          'userEmail': email,      // Updated field name
          'userPassword': password, // Updated field name
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw ApiException(
          data['error'] ?? 'Registration failed',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on HttpException {
      throw ApiException('Server error', 500);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['error'] ?? 'Logout failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Logout failed: ${e.toString()}', 0);
    }
  }

  Future<UserModel> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['error'] ?? 'Failed to fetch user profile',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<UserModel> updateProfile(int userId, String userName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'userName': userName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['error'] ?? 'Failed to update profile',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  // ========== CATEGORY METHODS ==========
  Future<List<CategoryModel.Category>> getCategories(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CategoryModel.Category.fromJson(json)).toList();
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to fetch categories',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on HttpException {
      throw ApiException('Server error', 500);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<List<CategoryModel.Category>> getIncomeCategories(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/income/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CategoryModel.Category.fromJson(json)).toList();
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to fetch income categories',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<List<CategoryModel.Category>> getExpenseCategories(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/expense/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CategoryModel.Category.fromJson(json)).toList();
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to fetch expense categories',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<CategoryModel.Category> createCategory(String categoryName, bool isExpense, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/user/$userId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'categoryName': categoryName,
          'isExpense': isExpense,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return CategoryModel.Category.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to create category',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  // Tambahkan method updateCategory yang hilang
  Future<CategoryModel.Category> updateCategory(int categoryId, String categoryName, bool isExpense, int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$categoryId/user/$userId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'categoryName': categoryName,
          'isExpense': isExpense,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CategoryModel.Category.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to update category',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  // Tambahkan method deleteCategory yang hilang
  Future<void> deleteCategory(int categoryId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$categoryId/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to delete category',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  // ========== TRANSACTION METHODS ==========
  Future<List<Transaction>> getTransactions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to fetch transactions',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(transaction.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to create transaction',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<Transaction> updateTransaction(int transactionId, Transaction transaction, int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$transactionId/user/$userId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(transaction.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to update transaction',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<void> deleteTransaction(int transactionId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$transactionId/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to delete transaction',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<TransactionSummary> getMonthlySummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/summary/monthly/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TransactionSummary.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to fetch monthly summary',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<TransactionSummary> getYearlySummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/summary/yearly/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TransactionSummary.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to fetch yearly summary',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }

  Future<Dashboard> getDashboard(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/user/$userId'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Dashboard.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to fetch dashboard data',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
