import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Function(Expense) onDelete;

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No expenses yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to add your first expense',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = expenses[index];
          return Dismissible(
            key: Key(expense.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) {
              onDelete(expense);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(expense.category),
                  child: Text(
                    expense.category[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.category),
                    Text(
                      DateFormat('MMM dd, yyyy').format(expense.date),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Text(
                  '\$${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                onTap: () {
                  // Navigate to expense detail screen
                },
              ),
            ),
          );
        },
        childCount: expenses.length,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return Colors.orange;
      case 'Transportation':
        return Colors.blue;
      case 'Shopping':
        return Colors.purple;
      case 'Entertainment':
        return Colors.pink;
      case 'Bills & Utilities':
        return Colors.red;
      case 'Healthcare':
        return Colors.green;
      case 'Education':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}