import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service_with_cookies.dart';

class AuthService extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  int? _userId;
  String? _userName;
  String? _userEmail;
  String? _sessionId;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get sessionId => _sessionId;

  // Login method
  Future<bool> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      
      print('AuthService: Attempting login for $email');
      
      final response = await ApiService.login(email, password);
      
      if (response['success'] == true) {
        final userData = response['user'];
        
        _userId = userData['userId'];
        _userName = userData['userName'];
        _userEmail = userData['userEmail'];
        _sessionId = response['sessionId']; // Simpan session ID
        _isAuthenticated = true;
        
        // Save to SharedPreferences
        await _saveUserData();
        
        print('AuthService: Login successful');
        print('Session ID: $_sessionId');
        
        // Debug: Print cookies
        ApiService.printCookies();
        
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('AuthService login error: $e');
      _clearUserData();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Register method
  Future<bool> register({required String name, required String email, required String password}) async {
    try {
      _setLoading(true);
      
      final response = await ApiService.register(name, email, password);
      
      if (response['success'] == true) {
        print('AuthService: Registration successful');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('AuthService register error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      await ApiService.logout();
      await _clearUserData();
      
      print('AuthService: Logout successful');
      notifyListeners();
    } catch (e) {
      print('AuthService logout error: $e');
      // Clear local data even if API call fails
      await _clearUserData();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Check session status
  Future<void> checkSessionStatus() async {
    try {
      final response = await ApiService.checkSessionStatus();
      
      if (response['authenticated'] == true) {
        _userId = response['userId'];
        _userEmail = response['userEmail'];
        _sessionId = response['sessionId'];
        _isAuthenticated = true;
        
        print('Session is active: $_sessionId');
      } else {
        _clearUserData();
        print('No active session');
      }
      
      notifyListeners();
    } catch (e) {
      print('Session check error: $e');
      _clearUserData();
      notifyListeners();
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userId != null) await prefs.setInt('userId', _userId!);
    if (_userName != null) await prefs.setString('userName', _userName!);
    if (_userEmail != null) await prefs.setString('userEmail', _userEmail!);
    if (_sessionId != null) await prefs.setString('sessionId', _sessionId!);
    await prefs.setBool('isAuthenticated', _isAuthenticated);
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _userId = null;
    _userName = null;
    _userEmail = null;
    _sessionId = null;
    _isAuthenticated = false;
  }

  // Load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _userId = prefs.getInt('userId');
      _userName = prefs.getString('userName');
      _userEmail = prefs.getString('userEmail');
      _sessionId = prefs.getString('sessionId');
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      
      // Verify session is still active
      if (_isAuthenticated) {
        await checkSessionStatus();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _clearUserData();
      notifyListeners();
    }
  }
}
