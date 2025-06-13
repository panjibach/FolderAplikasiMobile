import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:utsproject/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Base URL API - ganti dengan URL backend Anda
  final String baseUrl = 'http://10.0.2.2:8080/api/user'; // Untuk emulator Android
  // final String baseUrl = 'http://localhost:8080/api/user'; // Untuk iOS simulator

  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Headers untuk request
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Method untuk register user baru
  Future<User> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: headers,
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        // Parse response body
        final Map<String, dynamic> data = jsonDecode(response.body);
        User newUser = User.fromJson(data);

        // Simpan data user ke SharedPreferences
        await _saveUserToPrefs(newUser);

        return newUser;
      } else {
        throw Exception('Gagal mendaftarkan pengguna: ${response.body}');
      }
    } catch (e) {
      print('Error pada register: $e');
      throw Exception('Terjadi kesalahan saat mendaftarkan pengguna: $e');
    }
  }

  // Method untuk login user
  Future<User> login(String email, String password) async {
    try {
      // Buat objek untuk login
      final loginData = {
        'email': email,
        'password': password,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: headers,
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        // Parse response body
        final Map<String, dynamic> data = jsonDecode(response.body);
        User loggedInUser = User.fromJson(data);

        // Simpan data user ke SharedPreferences
        await _saveUserToPrefs(loggedInUser);

        return loggedInUser;
      } else {
        throw Exception('Gagal login: ${response.body}');
      }
    } catch (e) {
      print('Error pada login: $e');
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  // Method untuk update profil user
  Future<User> updateProfile(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${user.id}'),
        headers: headers,
        body: jsonEncode(user.toJsonForUpdate()),
      );

      if (response.statusCode == 200) {
        // Parse response body
        final Map<String, dynamic> data = jsonDecode(response.body);
        User updatedUser = User.fromJson(data);

        // Update data user di SharedPreferences
        await _saveUserToPrefs(updatedUser);

        return updatedUser;
      } else {
        throw Exception('Gagal memperbarui profil: ${response.body}');
      }
    } catch (e) {
      print('Error pada updateProfile: $e');
      throw Exception('Terjadi kesalahan saat memperbarui profil: $e');
    }
  }

  // Method untuk mengubah password
  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    try {
      final changePasswordData = {
        'userId': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: headers,
        body: jsonEncode(changePasswordData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error pada changePassword: $e');
      throw Exception('Terjadi kesalahan saat mengubah password: $e');
    }
  }

  // Method untuk logout
  Future<void> logout() async {
    try {
      // Hapus data user dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      print('Error pada logout: $e');
      throw Exception('Terjadi kesalahan saat logout: $e');
    }
  }

  // Method untuk mendapatkan user yang sedang login
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }

      return null;
    } catch (e) {
      print('Error pada getCurrentUser: $e');
      return null;
    }
  }

  // Method untuk menyimpan data user ke SharedPreferences
  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Hapus password sebelum menyimpan ke SharedPreferences
      user.password = null;
      await prefs.setString('user_data', jsonEncode(user.toJson()));
    } catch (e) {
      print('Error menyimpan user ke SharedPreferences: $e');
    }
  }

  // Method untuk mendapatkan semua user (admin only)
  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Parse response body
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mendapatkan daftar pengguna: ${response.body}');
      }
    } catch (e) {
      print('Error pada getAllUsers: $e');
      throw Exception('Terjadi kesalahan saat mendapatkan daftar pengguna: $e');
    }
  }

  // Method untuk menghapus user (soft delete)
  Future<bool> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$userId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error pada deleteUser: $e');
      throw Exception('Terjadi kesalahan saat menghapus pengguna: $e');
    }
  }
}
