class Category {
  final int? id;
  final String name;
  final bool isExpense;
  final bool deleted;

  Category({
    this.id,
    required this.name,
    required this.isExpense,
    this.deleted = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Debugging untuk melihat isi JSON
    print('Category JSON: $json');

    // Field expense di Java menggunakan @JsonProperty("expense")
    bool isExpenseValue = false;
    if (json.containsKey('expense')) {
      isExpenseValue = json['expense'] ?? false;
    } else if (json.containsKey('isExpense')) {
      isExpenseValue = json['isExpense'] ?? false;
    }

    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      isExpense: isExpenseValue,
      deleted: json['deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expense': isExpense, // Gunakan 'expense' untuk backend
    };
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, isExpense: $isExpense}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}