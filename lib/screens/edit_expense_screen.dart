import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/expense_form.dart';

class EditExpenseScreen extends StatelessWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return ExpenseForm(expense: expense);
  }
}