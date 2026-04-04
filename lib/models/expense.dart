class Expense {
  int? id;
  String title;
  double amount;
  String category;
  String? subcategory;
  DateTime date;
  String? note;
  String? receiptPath;
  List<String> tags; // Add tags field

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.subcategory,
    required this.date,
    this.note,
    this.receiptPath,
    this.tags = const [], // Initialize as empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'date': date.toIso8601String(),
      'note': note,
      'receiptPath': receiptPath,
      'tags': tags.join(','), // Store tags as comma-separated string
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
      note: map['note'],
      receiptPath: map['receiptPath'],
      tags: map['tags'] != null && map['tags'].toString().isNotEmpty
          ? (map['tags'] as String).split(',').map((t) => t.trim()).toList()
          : [],
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, category: $category, subcategory: $subcategory, tags: $tags, date: $date)';
  }
}