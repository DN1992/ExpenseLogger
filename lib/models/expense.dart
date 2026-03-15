class Expense {
  int? id;
  String title;
  double amount;
  String category;
  DateTime date;
  String? note;
  String? receiptPath;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.receiptPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'receiptPath': receiptPath,
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
      date: DateTime.parse(map['date']),
      note: map['note'],
      receiptPath: map['receiptPath'],
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, category: $category, date: $date)';
  }
}