import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _token;
  UserModel? _user;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  UserModel? get user => _user;
  int? get userId => _user?.userId;
  String? get userName => _user?.userName;
  String? get userEmail => _user?.userEmail;
  // Tambahkan getter profileUrl yang hilang
  String? get profileUrl => _user?.profileUrl;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      // Parse response according to Spring Boot backend format
      _token = response['token'];
      _user = UserModel.fromJson(response['user']);
      _isLoggedIn = true;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setInt('user_id', _user!.userId);
      await prefs.setString('user_name', _user!.userName);
      await prefs.setString('user_email', _user!.userEmail);

      return true;
    } catch (e) {
      _isLoggedIn = false;
      _token = null;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(name, email, password);
      
      // Parse response according to Spring Boot backend format
      _user = UserModel.fromJson(response);
      _isLoggedIn = true;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', _user!.userId);
      await prefs.setString('user_name', _user!.userName);
      await prefs.setString('user_email', _user!.userEmail);

      return true;
    } catch (e) {
      _isLoggedIn = false;
      _token = null;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      
      if (userId != null && userName != null && userEmail != null) {
        _user = UserModel(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          isDeleted: false,
        );
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      // Call backend logout API
      await _apiService.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
      print('Logout API call failed: $e');
    }

    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    
    _isLoggedIn = false;
    _token = null;
    _user = null;
    notifyListeners();
  }

  // Perbaiki method updateProfile untuk menerima named parameter
  Future<void> updateProfile({String? userName}) async {
    if (_user == null || userName == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _apiService.updateProfile(_user!.userId, userName);
      _user = updatedUser;

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', updatedUser.userName);

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
