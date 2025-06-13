import 'package:flutter/material.dart';
import 'package:utsproject/models/category.dart';
import 'package:utsproject/models/transaction.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:utsproject/services/category_services.dart';
import 'package:decimal/decimal.dart';


class TransactionService extends ChangeNotifier {
  // Singleton pattern
  static final TransactionService _instance = TransactionService._internal();
  final Uuid _uuid = const Uuid();

  factory TransactionService() {
    return _instance;
  }

  TransactionService._internal();

  final List<Transaction> _transactions = [];

  // Gunakan 10.0.2.2 untuk emulator Android
  final String baseUrl = 'http://localhost:8081/api/transactions';

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  // Mendapatkan semua transaksi (tidak termasuk yang di-soft delete)
  Future<void> fetchTransactions() async {
    try {
      print('===== FETCH TRANSACTIONS START =====');
      print('URL: $baseUrl');

      final response = await http.get(Uri.parse(baseUrl));
      print('Fetch Transactions Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response body length: ${response.body.length}');
        if (response.body.length > 0) {
          print('Response body preview: ${response.body.substring(
              0, min(100, response.body.length))}...');
        } else {
          print('Response body is empty');
        }

        if (response.body.isEmpty) {
          print('Response body is empty');
          _transactions.clear();
          notifyListeners();
          return;
        }

        try {
          final List<dynamic> data = json.decode(response.body);
          print('Successfully decoded JSON. Found ${data.length} transactions');

          if (data.isEmpty) {
            print('No transactions returned from backend');
            _transactions.clear();
            notifyListeners();
            return;
          }

          print('First transaction data: ${data.isNotEmpty
              ? data.first
              : "No data"}');

          _transactions.clear();
          for (var item in data) {
            try {
              final transaction = Transaction.fromJson(item);
              _transactions.add(transaction);
              print('Added transaction: ${transaction.id}, ${transaction
                  .amount}, ${transaction.category.name}, ${DateFormat(
                  'yyyy-MM-dd').format(transaction.date)}');
            } catch (e) {
              print('Error parsing transaction: $e');
              print('Problematic data: $item');
            }
          }

          print('Total transactions loaded: ${_transactions.length}');
          notifyListeners();
        } catch (e) {
          print('JSON decode error: $e');
          print('Raw response: ${response.body}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        print('Error body: ${response.body}');
      }
      print('===== FETCH TRANSACTIONS END =====');
    } catch (e) {
      print('Exception in fetchTransactions: $e');
    }
  }

  // Method to get transactions by date
  List<Transaction> getTransactionsByDate(DateTime date) {
    // Convert date to string format YYYY-MM-DD for simple comparison
    final String dateString = DateFormat('yyyy-MM-dd').format(date);

    // Debug log
    debugPrint('Filtering for date: $dateString');

    final result = _transactions.where((tx) {
      // Convert transaction date to same string format
      final String txDateString = DateFormat('yyyy-MM-dd').format(tx.date);

      // Simple string comparison
      return txDateString == dateString;
    }).toList();

    // Debug log for each transaction found
    for (var tx in result) {
      debugPrint(
          'Transaction found: ID=${tx.id}, Date=${DateFormat('yyyy-MM-dd')
              .format(tx.date)}, Category=${tx.category.name}, Amount=${tx
              .amount}');
    }

    return result;
  }

  // Method to get transactions by month
  List<Transaction> getTransactionsByMonth(DateTime date) {
    final int year = date.year;
    final int month = date.month;

    // Debug log
    debugPrint('Filtering for month: $month/$year');

    final result = _transactions.where((tx) {
      return tx.date.year == year && tx.date.month == month;
    }).toList();

    debugPrint('Found ${result.length} transactions for month $month/$year');

    // Debug log for each transaction found
    for (var tx in result) {
      debugPrint(
          'Transaction found: ID=${tx.id}, Date=${DateFormat('yyyy-MM-dd')
              .format(tx.date)}, Category=${tx.category.name}, Amount=${tx
              .amount}');
    }

    return result;
  }

  // Method to get total income for a month
  double getTotalIncomeForMonth(DateTime date) {
    final transactions = getTransactionsByMonth(date);
    double total = 0;

    for (var tx in transactions) {
      if (!tx.category.isExpense) {
        total += tx.amount.toDouble(); // Konversi Decimal ke double
      }
    }

    return total;
  }

  // Method to get total expense for a month
  double getTotalExpenseForMonth(DateTime date) {
    final transactions = getTransactionsByMonth(date);
    double total = 0;

    for (var tx in transactions) {
      if (tx.category.isExpense) {
        total += tx.amount.toDouble(); // Konversi Decimal ke double
      }
    }

    return total;
  }

  // Method to get income transactions for a month
  List<Transaction> getIncomeTransactionsForMonth(DateTime date) {
    final transactions = getTransactionsByMonth(date);
    return transactions.where((tx) => !tx.category.isExpense).toList();
  }

  // Method to get expense transactions for a month
  List<Transaction> getExpenseTransactionsForMonth(DateTime date) {
    final transactions = getTransactionsByMonth(date);
    return transactions.where((tx) => tx.category.isExpense).toList();
  }

  // Tambah transaksi baru
  Future<void> addTransaction(String amount, Category? category,
      String description, {DateTime? date}) async {
    if (category == null) return;

    final transactionDate = date ?? DateTime.now();

    try {
      // Bersihkan format rupiah (misalnya, "Rp. 100.000" menjadi "100000")
      String cleanedAmount = amount.replaceAll('Rp. ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      Decimal amountValue = Decimal.parse(cleanedAmount);

      final Map<String, dynamic> data = {
        'amount': amountValue.toString(), // Kirim sebagai string untuk backend
        'category': {'id': category.id},
        'date': DateFormat('yyyy-MM-dd').format(transactionDate),
        'description': description,
      };

      print('Mengirim data transaksi: ${json.encode(data)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print('Respons tambah transaksi: ${response.statusCode} - ${response
          .body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newTransaction = Transaction.fromJson(json.decode(response.body));
        _transactions.add(newTransaction);
        notifyListeners();
      } else {
        throw Exception(
            'Gagal menambahkan transaksi: ${response.statusCode} - ${response
                .body}');
      }
    } catch (e) {
      print('Error tambah transaksi: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Edit transaksi
  Future<void> editTransaction(String id, String amount, Category? category,
      String description, {DateTime? date}) async {
    if (category == null) return;

    final transactionDate = date ?? DateTime.now();

    try {
      // Bersihkan format rupiah dan konversi ke Decimal
      String cleanedAmount = amount.replaceAll('Rp. ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      Decimal amountValue = Decimal.parse(cleanedAmount);

      final Map<String, dynamic> data = {
        'amount': amountValue.toString(),
        'category': {'id': category.id},
        'date': DateFormat('yyyy-MM-dd').format(transactionDate),
        'description': description,
      };

      print('Mengedit data transaksi: ${json.encode(data)}');

      final idInt = int.tryParse(id);
      if (idInt == null) {
        throw Exception('ID transaksi tidak valid');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$idInt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print(
          'Respons edit transaksi: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final updatedTransaction = Transaction.fromJson(
            json.decode(response.body));
        final index = _transactions.indexWhere((tx) => tx.id == id);
        if (index != -1) {
          _transactions[index] = updatedTransaction;
          notifyListeners();
        }
      } else {
        throw Exception(
            'Gagal memperbarui transaksi: ${response.statusCode} - ${response
                .body}');
      }
    } catch (e) {
      print('Error edit transaksi: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Soft delete transaksi
  Future<void> removeTransaction(String id) async {
    try {
      print('Removing transaction with ID: $id');

      // Konversi id dari String ke int untuk URL
      final idInt = int.tryParse(id);
      if (idInt == null) {
        throw Exception('ID transaksi tidak valid');
      }

      final response = await http.delete(Uri.parse('$baseUrl/$idInt'));
      print('Remove transaction response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _transactions.removeWhere((tx) => tx.id == id);
        notifyListeners();
      } else {
        throw Exception(
            'Gagal menghapus transaksi: ${response.statusCode} - ${response
                .body}');
      }
    } catch (e) {
      print('Remove Transaction Error: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Untuk kompatibilitas dengan kode yang sudah ada
  void addTransactionLocal(String amount, Category? category, String description, {DateTime? date}) {
    if (category == null) return;

    // Gunakan tanggal yang diberikan atau tanggal saat ini, tanpa komponen waktu
    final DateTime providedDate = date ?? DateTime.now();
    final DateTime transactionDate = DateTime(providedDate.year, providedDate.month, providedDate.day);

    // Debug log
    debugPrint('Menambahkan transaksi dengan tanggal: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(transactionDate)}');

    // Bersihkan format rupiah (misalnya, "Rp. 100.000" menjadi "100000")
    String cleanedAmount = amount.replaceAll('Rp. ', '').replaceAll('.', '').replaceAll(',', '.');
    Decimal amountValue;
    try {
      amountValue = Decimal.parse(cleanedAmount);
    } catch (e) {
      print('Error parsing amount: $e');
      return; // Keluar jika parsing gagal
    }

    final transaction = Transaction(
      id: _uuid.v4(),
      amount: amountValue, // Gunakan Decimal
      category: category,
      description: description,
      date: transactionDate,
    );

    _transactions.add(transaction);
    notifyListeners();
  }

  // Debug method to print all transactions
  void debugPrintAllTransactions() {
    debugPrint('===== ALL TRANSACTIONS =====');
    for (var tx in _transactions) {
      debugPrint('ID: ${tx.id}, Date: ${DateFormat('yyyy-MM-dd').format(
          tx.date)}, Category: ${tx.category.name}, isExpense: ${tx.category
          .isExpense}, Amount: ${tx.amount}');
    }
    debugPrint('===========================');
  }

  // Metode untuk menguji koneksi ke backend
  Future<void> testBackendConnection() async {
    try {
      print('Testing connection to backend...');

      // Test GET /api/transactions
      final response = await http.get(Uri.parse(baseUrl));
      print('Test connection response: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      if (response.body.isNotEmpty) {
        print('Response body preview: ${response.body.substring(
            0, min(100, response.body.length))}...');
      } else {
        print('Response body is empty');
      }

      // Test OPTIONS /api/transactions (untuk CORS)
      try {
        final optionsResponse = await http.head(Uri.parse(baseUrl));
        print('OPTIONS response: ${optionsResponse.statusCode}');
        print('OPTIONS headers: ${optionsResponse.headers}');
      } catch (e) {
        print('OPTIONS request failed: $e');
      }

      print('Connection test completed successfully');
    } catch (e) {
      print('Connection test failed: $e');
    }
  }

  // Tambahkan transaksi dummy untuk testing
  void addDummyTransaction() {
    print('Menambahkan transaksi dummy untuk pengujian');

    final categoryService = CategoryService();
    final categories = categoryService.categories;

    if (categories.isNotEmpty) {
      final dummyCategory = categories.first;

      final dummyTransaction = Transaction(
        id: 'dummy-${DateTime
            .now()
            .millisecondsSinceEpoch}',
        amount: Decimal.parse('100000'),
        // Konversi ke Decimal
        category: dummyCategory,
        date: DateTime.now(),
        description: 'Transaksi dummy untuk pengujian',
        deleted: false,
      );

      _transactions.add(dummyTransaction);
      print('Transaksi dummy ditambahkan: ${dummyTransaction
          .id}, ${dummyTransaction.amount}');
      notifyListeners();
    } else {
      print('Tidak ada kategori tersedia untuk transaksi dummy');
    }
  }

// Helper function untuk min
  int min(int a, int b) {
    return a < b ? a : b;
  }
}