import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../models/categories.dart';
import '../models/user_category.dart';

class SubcategoryChart extends StatelessWidget {
  final List<Expense> expenses;
  final String category;

  const SubcategoryChart({
    super.key,
    required this.expenses,
    required this.category,
  });

  Map<String, double> _getSubcategoryTotals() {
    Map<String, double> totals = {};
    final categoryExpenses = expenses.where((e) => e.category == category);
    
    for (var expense in categoryExpenses) {
      String key = expense.subcategory ?? 'General';
      totals[key] = (totals[key] ?? 0) + expense.amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _getSubcategoryTotals();
    
    if (totals.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoryColor = categories.firstWhere(
      (c) => c.name == category,
      orElse: () => categories.last,
    ).color;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$category - Subcategory Breakdown',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: totals.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${(entry.value / totals.values.fold(0.0, (a, b) => a + b) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      color: categoryColor.withOpacity(0.5 + (totals.keys.toList().indexOf(entry.key) * 0.1).clamp(0.3, 0.9)),
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
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
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: categoryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.5 + (totals.keys.toList().indexOf(entry.key) * 0.1).clamp(0.3, 0.9)),
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
}