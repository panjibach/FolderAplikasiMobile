import 'package:flutter/material.dart';
import 'package:utsproject/models/category.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService extends ChangeNotifier {
  // Singleton pattern
  static final CategoryService _instance = CategoryService._internal();

  factory CategoryService() => _instance;
  CategoryService._internal();

  final List<Category> _categories = [];
  // Gunakan 10.0.2.2 untuk emulator Android
  final String baseUrl = 'http://localhost:8081/api/categories';

  List<Category> get categories => _categories;

  Future<void> fetchCategories() async {
    try {
      print('===== FETCH CATEGORIES START =====');
      print('URL: $baseUrl');

      final response = await http.get(Uri.parse(baseUrl));
      print('Fetch Categories Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response body length: ${response.body.length}');
        print('Response body preview: ${response.body.substring(0, min(100, response.body.length))}...');

        final List data = json.decode(response.body);
        print('Parsed Categories: $data');

        _categories.clear();

        // Proses setiap item satu per satu untuk menangkap error individual
        for (var item in data) {
          try {
            final category = Category.fromJson(item);
            _categories.add(category);
          } catch (e) {
            print('Error parsing category: $e, data: $item');
            // Lanjutkan ke item berikutnya
          }
        }

        print('Loaded Categories: ${_categories.map((c) => c.name).toList()}');
        notifyListeners();
      } else {
        print('HTTP error: ${response.statusCode}');
        print('Error body: ${response.body}');
        throw Exception('Gagal mengambil data kategori: ${response.statusCode}');
      }
      print('===== FETCH CATEGORIES END =====');
    } catch (e) {
      print('Fetch Categories Error: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      print('Adding category: ${category.name}, isExpense: ${category.isExpense}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      );

      print('Add category response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newCategory = Category.fromJson(json.decode(response.body));
        _categories.add(newCategory);
        notifyListeners();
      } else {
        throw Exception('Gagal menambahkan kategori: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Add Category Error: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      print('Deleting category with ID: $id');

      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      print('Delete category response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
      } else {
        throw Exception('Gagal menghapus kategori: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Delete Category Error: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  Future<void> editCategory(Category category, String newName) async {
    if (category.id == null) {
      throw Exception('Category ID tidak boleh null');
    }

    try {
      print('Editing category with ID: ${category.id}, new name: $newName');

      final response = await http.put(
        Uri.parse('$baseUrl/${category.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': newName,
          'expense': category.isExpense,
        }),
      );

      print('Edit category response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final updatedCategory = Category.fromJson(json.decode(response.body));
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = updatedCategory;
          notifyListeners();
        }
      } else {
        throw Exception('Gagal memperbarui kategori: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Edit Category Error: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  List<Category> getExpenseCategories() {
    return _categories.where((category) => category.isExpense).toList();
  }

  List<Category> getIncomeCategories() {
    return _categories.where((category) => !category.isExpense).toList();
  }

  // Metode untuk menguji koneksi ke backend
  Future<void> testBackendConnection() async {
    try {
      print('Testing connection to backend...');

      final response = await http.get(Uri.parse(baseUrl));
      print('Test connection response: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body preview: ${response.body.substring(0, min(100, response.body.length))}...');

      print('Connection test completed successfully');
    } catch (e) {
      print('Connection test failed: $e');
    }
  }
}

// Helper function untuk min
int min(int a, int b) {
  return a < b ? a : b;
}