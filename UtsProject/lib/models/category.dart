class Category {
  final int? categoryId;
  final String categoryName;
  final bool isExpense;
  final bool isDeleted;
  final int? createdByUserId;

  Category({
    this.categoryId,
    required this.categoryName,
    required this.isExpense,
    this.isDeleted = false,
    this.createdByUserId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      isExpense: json['isExpense'],
      isDeleted: json['isDeleted'] ?? false,
      createdByUserId: json['createdByUserId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isExpense': isExpense,
      'isDeleted': isDeleted,
      'createdByUserId': createdByUserId,
    };
  }

  // Getter for compatibility with existing code
  String get name => categoryName;
  int? get id => categoryId;

  Category copyWith({
    int? categoryId,
    String? categoryName,
    bool? isExpense,
    bool? isDeleted,
    int? createdByUserId,
  }) {
    return Category(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isExpense: isExpense ?? this.isExpense,
      isDeleted: isDeleted ?? this.isDeleted,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }
}
