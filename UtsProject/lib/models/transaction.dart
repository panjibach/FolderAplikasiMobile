import 'package:utsproject/models/category.dart';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';

class Transaction {
  final String id; // Tetap gunakan String di Flutter
  final Decimal amount; // Format tampilan untuk UI
  final Category category;
  final DateTime date;
  final String description;
  final bool deleted;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    this.deleted = false,
  });

  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2,
    );
    // Directly format the Decimal to avoid precision issues with double
    return formatter.format(amount.toDouble());
  }

  /// Create object from JSON (backend -> Flutter)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      return Transaction(
        id: json['id']?.toString() ?? '',
        amount: Decimal.tryParse(json['amount']?.toString() ?? '0') ?? Decimal.zero,
        category: json['category'] != null
            ? Category.fromJson(json['category'])
            : Category(id: 0, name: 'Unknown', isExpense: false),
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        description: json['description']?.toString() ?? '',
        deleted: json['deleted'] as bool? ?? false,
      );
    } catch (e) {
      print('Error creating Transaction from JSON: $e');
      rethrow;
    }
  }

  /// Convert object to JSON (Flutter -> backend)
  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'amount': amount.toString(), // Backend expects BigDecimal as string
        'category': {'id': category.id},
        'date': DateFormat('yyyy-MM-dd').format(date),
        'description': description,
        'deleted': deleted,
      };
    } catch (e) {
      print('Error converting Transaction to JSON: $e');
      return {};
    }
  }

  @override
  String toString() {
    return 'Transaction{id: $id, amount: $formattedAmount, category: ${category.name}, date: ${DateFormat('yyyy-MM-dd').format(date)}, description: $description, deleted: $deleted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}