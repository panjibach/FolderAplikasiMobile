import 'package:intl/intl.dart';
import 'category.dart' as CategoryModel;

class Transaction {
  final int? transactionId;
  final double transactionAmount;
  final String? transactionDescription;
  final DateTime transactionDate;
  final int categoryId;
  final int? userId;
  final bool isDeleted;
  final String? transactionType;
  
  // Add these properties for UI compatibility
  CategoryModel.Category? _category;

  Transaction({
    this.transactionId,
    required this.transactionAmount,
    this.transactionDescription,
    required this.transactionDate,
    required this.categoryId,
    this.userId,
    this.isDeleted = false,
    this.transactionType,
    CategoryModel.Category? category,
  }) : _category = category;

  // Add getters for backward compatibility
  int? get id => transactionId;
  String get description => transactionDescription ?? '';
  DateTime get date => transactionDate;
  CategoryModel.Category get category => _category ?? CategoryModel.Category(
    categoryId: categoryId,
    categoryName: 'Unknown Category',
    isExpense: true,
    isDeleted: false,
  );

  // ✅ PERBAIKAN: Tambahkan getter type yang hilang
  String get type {
    if (_category != null) {
      return _category!.isExpense ? 'expense' : 'income';
    }
    // Fallback jika category tidak ada
    return 'expense';
  }

  // Add isExpense getter based on category
  bool get isExpense => _category?.isExpense ?? true;

  // Tambahkan getter categoryName untuk kompatibilitas dengan UI
  String get categoryName => _category?.categoryName ?? 'Unknown Category';
  
  // Tambahkan getter name untuk kompatibilitas dengan UI
  String get name => categoryName;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId'],
      transactionAmount: (json['transactionAmount'] as num).toDouble(),
      transactionDescription: json['transactionDescription'],
      transactionDate: DateTime.parse(json['transactionDate']),
      categoryId: json['categoryId'],
      userId: json['userId'],
      isDeleted: json['isDeleted'] ?? false,
      transactionType: json['transactionType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'transactionAmount': transactionAmount,
      'transactionDescription': transactionDescription,
      'transactionDate': transactionDate.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      'categoryId': categoryId,
      'userId': userId,
      'isDeleted': isDeleted,
      'transactionType': transactionType,
    };
  }

  String get formattedAmount {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(transactionAmount);
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy', 'id').format(transactionDate);
  }

  Transaction copyWith({
    int? transactionId,
    double? transactionAmount,
    String? transactionDescription,
    DateTime? transactionDate,
    int? categoryId,
    int? userId,
    bool? isDeleted,
    String? transactionType,
    CategoryModel.Category? category,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      transactionDescription: transactionDescription ?? this.transactionDescription,
      transactionDate: transactionDate ?? this.transactionDate,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this._category,
    );
  }

  // Method to set category after fetching from CategoryService
  void setCategory(CategoryModel.Category category) {
    _category = category;
  }
}
