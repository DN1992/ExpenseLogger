class Expense {
  int? id;
  String title;
  double amount;
  String category;
  String? subcategory;
  DateTime date;
  List<String> tags;
  bool isFoodSubsidy;  // New field for food subsidy

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.subcategory,
    required this.date,
    this.tags = const [],
    this.isFoodSubsidy = false,  // Default to false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'date': date.toIso8601String(),
      'tags': tags.join(','),
      'isFoodSubsidy': isFoodSubsidy ? 1 : 0,  // Store as integer
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'] is int 
          ? (map['amount'] as int).toDouble() 
          : map['amount'] as double,
      category: map['category'],
      subcategory: map['subcategory'],
      date: DateTime.parse(map['date']),
      tags: map['tags'] != null && map['tags'].toString().isNotEmpty
          ? (map['tags'] as String).split(',').map((t) => t.trim()).toList()
          : [],
      isFoodSubsidy: map['isFoodSubsidy'] == 1,  // Convert from integer
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, category: $category, subcategory: $subcategory, tags: $tags, isFoodSubsidy: $isFoodSubsidy, date: $date)';
  }
}