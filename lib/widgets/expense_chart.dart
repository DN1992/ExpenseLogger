import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  Map<String, double> _getCategoryTotals() {
    Map<String, double> totals = {};
    for (var expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<PieChartSectionData> _getSections() {
    final totals = _getCategoryTotals();
    final totalAmount = totals.values.fold(0.0, (sum, amount) => sum + amount);
    
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.green,
      Colors.teal,
      Colors.grey,
    ];

    return totals.entries.map((entry) {
      final percentage = (entry.value / totalAmount * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: entry.value,
        title: '$percentage%',
        radius: 50,
        color: colors[totals.keys.toList().indexOf(entry.key) % colors.length],
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _getCategoryTotals();
    
    if (totals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: totals.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                      const SizedBox(width: 4),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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