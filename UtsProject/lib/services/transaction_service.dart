import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/transaction_summary.dart';
import '../models/dashboard.dart';
import '../models/category.dart' as CategoryModel;
import 'api_service.dart';
import 'auth_services.dart';
import 'category_services.dart';
import '../main.dart' show navigatorKey;

class TransactionService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Transaction> _transactions = [];
  TransactionSummary? _monthlySummary;
  TransactionSummary? _yearlySummary;
  Dashboard? _dashboard;
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  TransactionSummary? get monthlySummary => _monthlySummary;
  TransactionSummary? get yearlySummary => _yearlySummary;
  Dashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get transactions by date
  List<Transaction> getTransactionsByDate(DateTime date) {
    return _transactions.where((transaction) {
      return transaction.transactionDate.year == date.year &&
             transaction.transactionDate.month == date.month &&
             transaction.transactionDate.day == date.day &&
             !transaction.isDeleted;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  // Get transactions by month
  List<Transaction> getTransactionsByMonth(DateTime month) {
    return _transactions.where((transaction) {
      return transaction.transactionDate.year == month.year &&
             transaction.transactionDate.month == month.month &&
             !transaction.isDeleted;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  // Get transactions by date range
  List<Transaction> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return _transactions.where((transaction) {
      return transaction.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transaction.transactionDate.isBefore(endDate.add(const Duration(days: 1))) &&
             !transaction.isDeleted;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  // Get total income for month
  double getTotalIncomeForMonth(DateTime month) {
    final context = navigatorKey.currentContext;
    if (context == null) return 0.0;

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final incomeCategories = categoryService.getIncomeCategories();
    final incomeCategoryIds = incomeCategories.map((cat) => cat.categoryId).toSet();

    return _transactions
        .where((transaction) =>
            transaction.transactionDate.year == month.year &&
            transaction.transactionDate.month == month.month &&
            incomeCategoryIds.contains(transaction.categoryId) &&
            !transaction.isDeleted)
        .fold(0.0, (sum, transaction) => sum + transaction.transactionAmount);
  }

  // Get total expense for month
  double getTotalExpenseForMonth(DateTime month) {
    final context = navigatorKey.currentContext;
    if (context == null) return 0.0;

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final expenseCategories = categoryService.getExpenseCategories();
    final expenseCategoryIds = expenseCategories.map((cat) => cat.categoryId).toSet();

    return _transactions
        .where((transaction) =>
            transaction.transactionDate.year == month.year &&
            transaction.transactionDate.month == month.month &&
            expenseCategoryIds.contains(transaction.categoryId) &&
            !transaction.isDeleted)
        .fold(0.0, (sum, transaction) => sum + transaction.transactionAmount);
  }

  // Get expense transactions for month
  List<Transaction> getExpenseTransactionsForMonth(DateTime month) {
    final context = navigatorKey.currentContext;
    if (context == null) return [];

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final expenseCategories = categoryService.getExpenseCategories();
    final expenseCategoryIds = expenseCategories.map((cat) => cat.categoryId).toSet();

    final expenseTransactions = _transactions
        .where((transaction) =>
            transaction.transactionDate.year == month.year &&
            transaction.transactionDate.month == month.month &&
            expenseCategoryIds.contains(transaction.categoryId) &&
            !transaction.isDeleted)
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    // ✅ PERBAIKAN: Set category untuk setiap transaction
    for (var transaction in expenseTransactions) {
      final category = categoryService.getCategoryById(transaction.categoryId);
      if (category != null) {
        transaction.setCategory(category);
      }
    }

    return expenseTransactions;
  }

  // Get income transactions for month
  List<Transaction> getIncomeTransactionsForMonth(DateTime month) {
    final context = navigatorKey.currentContext;
    if (context == null) return [];

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final incomeCategories = categoryService.getIncomeCategories();
    final incomeCategoryIds = incomeCategories.map((cat) => cat.categoryId).toSet();

    final incomeTransactions = _transactions
        .where((transaction) =>
            transaction.transactionDate.year == month.year &&
            transaction.transactionDate.month == month.month &&
            incomeCategoryIds.contains(transaction.categoryId) &&
            !transaction.isDeleted)
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    // ✅ PERBAIKAN: Set category untuk setiap transaction
    for (var transaction in incomeTransactions) {
      final category = categoryService.getCategoryById(transaction.categoryId);
      if (category != null) {
        transaction.setCategory(category);
      }
    }

    return incomeTransactions;
  }

  // Remove transaction (for local operations)
  void removeTransaction(int? transactionId) {
    if (transactionId == null) return;
    
    _transactions.removeWhere((t) => t.transactionId == transactionId);
    notifyListeners();
  }

  // ✅ PERBAIKAN: Fetch all transactions dengan category linking
  Future<void> fetchTransactions() async {
    print('🔄 Starting fetchTransactions...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        throw Exception('Context not available');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      final userId = authService.userId;
      
      print('👤 Current userId: $userId');
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch transactions from API
      _transactions = await _apiService.getTransactions(userId);
      
      // ✅ PERBAIKAN: Link categories to transactions
      for (var transaction in _transactions) {
        final category = categoryService.getCategoryById(transaction.categoryId);
        if (category != null) {
          transaction.setCategory(category);
        } else {
          print('⚠️ Category not found for transaction ${transaction.transactionId}, categoryId: ${transaction.categoryId}');
        }
      }
      
      _error = null;
      
      print('✅ Fetched ${_transactions.length} transactions');
      
      // Debug: print first few transactions
      for (int i = 0; i < (_transactions.length > 3 ? 3 : _transactions.length); i++) {
        final t = _transactions[i];
        print('  Transaction $i: ${t.transactionAmount} - ${t.transactionDescription} - ${t.transactionDate} - Category: ${t.category.categoryName}');
      }
      
    } catch (e) {
      _error = e.toString();
      _transactions = [];
      print('❌ Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PERBAIKAN: Create new transaction dengan category linking
  Future<void> createTransaction({
    required double amount,
    required int categoryId,
    required DateTime date,
    String? description,
  }) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        throw Exception('Context not available');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Normalize date to avoid timezone issues
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final transaction = Transaction(
        transactionAmount: amount,
        transactionDescription: description,
        transactionDate: normalizedDate,
        categoryId: categoryId,
        userId: userId,
      );

      print('🔄 Creating transaction: ${transaction.toJson()}');

      final createdTransaction = await _apiService.createTransaction(transaction);
      
      // ✅ PERBAIKAN: Set category untuk transaction yang baru dibuat
      final category = categoryService.getCategoryById(createdTransaction.categoryId);
      if (category != null) {
        createdTransaction.setCategory(category);
      }
      
      _transactions.add(createdTransaction);
      
      // Sort transactions by date (newest first)
      _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      
      print('✅ Transaction created successfully: ${createdTransaction.transactionId}');
      
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      print('❌ Error creating transaction: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Update transaction
  Future<void> updateTransaction({
    required int transactionId,
    required double amount,
    required int categoryId,
    required DateTime date,
    String? description,
  }) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        throw Exception('Context not available');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Normalize date to avoid timezone issues
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final transaction = Transaction(
        transactionId: transactionId,
        transactionAmount: amount,
        transactionDescription: description,
        transactionDate: normalizedDate,
        categoryId: categoryId,
        userId: userId,
      );

      final updatedTransaction = await _apiService.updateTransaction(transactionId, transaction, userId);
      
      // ✅ PERBAIKAN: Set category untuk transaction yang diupdate
      final category = categoryService.getCategoryById(updatedTransaction.categoryId);
      if (category != null) {
        updatedTransaction.setCategory(category);
      }
      
      final index = _transactions.indexWhere((t) => t.transactionId == transactionId);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        notifyListeners();
      }
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(int transactionId) async {
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

      await _apiService.deleteTransaction(transactionId, userId);
      
      _transactions.removeWhere((t) => t.transactionId == transactionId);
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ✅ PERBAIKAN: Method untuk refresh data dengan category linking
  Future<void> refreshData() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    // Refresh categories first
    await categoryService.fetchCategories();
    
    // Then refresh transactions
    await fetchTransactions();
  }

  // Clear all data (for logout)
  void clearData() {
    _transactions.clear();
    _monthlySummary = null;
    _yearlySummary = null;
    _dashboard = null;
    _error = null;
    notifyListeners();
  }

  // Debug method
  void debugPrintAllTransactions() {
    print('=== ALL TRANSACTIONS (${_transactions.length}) ===');
    for (var transaction in _transactions) {
      print('ID: ${transaction.transactionId}, Amount: ${transaction.transactionAmount}, Date: ${transaction.transactionDate}, Category: ${transaction.categoryId} (${transaction.category.categoryName})');
    }
    print('=== END TRANSACTIONS ===');
  }
}
