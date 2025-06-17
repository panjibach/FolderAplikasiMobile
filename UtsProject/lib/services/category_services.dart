import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as CategoryModel; // ✅ Gunakan alias
import 'api_service.dart';
import 'auth_services.dart';
import '../main.dart' show navigatorKey;

class CategoryService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<CategoryModel.Category> _categories = []; // ✅ Gunakan alias
  bool _isLoading = false;
  String? _error;

  List<CategoryModel.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all categories (not deleted)
  List<CategoryModel.Category> getCategories() {
    return _categories.where((category) => !category.isDeleted).toList();
  }

  // Get expense categories
  List<CategoryModel.Category> getExpenseCategories() {
    return _categories.where((category) => category.isExpense && !category.isDeleted).toList();
  }

  // Get income categories
  List<CategoryModel.Category> getIncomeCategories() {
    return _categories.where((category) => !category.isExpense && !category.isDeleted).toList();
  }

  // Get category by ID
  CategoryModel.Category? getCategoryById(int categoryId) {
    try {
      return _categories.firstWhere((category) => category.categoryId == categoryId);
    } catch (e) {
      print('Category with ID $categoryId not found');
      return null;
    }
  }

  // Fetch all categories
  Future<void> fetchCategories() async {
    print('🔄 Starting fetchCategories...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        throw Exception('Context not available');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      print('👤 Current userId: $userId');
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      _categories = await _apiService.getCategories(userId);
      _error = null;
      
      print('✅ Fetched ${_categories.length} categories');
      
      // Debug: print first few categories
      for (int i = 0; i < (_categories.length > 3 ? 3 : _categories.length); i++) {
        final c = _categories[i];
        print('  Category $i: ${c.categoryName} - ${c.isExpense ? 'Expense' : 'Income'}');
      }
      
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new category
  Future<CategoryModel.Category> createCategory(String categoryName, bool isExpense) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        throw Exception('Context not available');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final category = await _apiService.createCategory(categoryName, isExpense, userId);
      _categories.add(category);
      notifyListeners();
      
      return category;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update category
  Future<CategoryModel.Category> updateCategory(int categoryId, String categoryName, bool isExpense) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        throw Exception('Context not available');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final updatedCategory = await _apiService.updateCategory(categoryId, categoryName, isExpense, userId);
      
      final index = _categories.indexWhere((c) => c.categoryId == categoryId);
      if (index != -1) {
        _categories[index] = updatedCategory;
        notifyListeners();
      }
      
      return updatedCategory;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(int categoryId) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        throw Exception('Context not available');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _apiService.deleteCategory(categoryId, userId);
      
      _categories.removeWhere((c) => c.categoryId == categoryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Clear all data (for logout)
  void clearData() {
    _categories.clear();
    _error = null;
    notifyListeners();
  }
}
