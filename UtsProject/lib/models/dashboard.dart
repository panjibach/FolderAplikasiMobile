class Dashboard {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int totalTransactions;
  final int totalCategories;

  Dashboard({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.totalTransactions,
    required this.totalCategories,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: json['totalTransactions'] ?? 0,
      totalCategories: json['totalCategories'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
      'totalTransactions': totalTransactions,
      'totalCategories': totalCategories,
    };
  }
}
