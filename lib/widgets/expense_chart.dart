import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../models/user_category.dart';

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  Map<String, double> _categoryTotals = {};
  Map<String, UserCategory> _categoryInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryColors();
  }

  Future<void> _loadCategoryColors() async {
    try {
      final dbService = DatabaseService();
      final categories = await dbService.getAllMainCategories();
      
      // Create a map for quick lookup
      for (var category in categories) {
        _categoryInfo[category.name] = category;
      }
      
      // Calculate totals
      _calculateTotals();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading category colors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTotals() {
    Map<String, double> totals = {};
    
    for (var expense in widget.expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    
    // Sort by amount (highest first)
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _categoryTotals = Map.fromEntries(sortedEntries);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalAmount = _categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

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
            const SizedBox(height: 8),
            Text(
              'Total: \$${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getPieSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Handle touch events if needed
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryTotals.entries.map((entry) {
                final categoryName = entry.key;
                final color = _getCategoryColor(categoryName);
                final percentage = (entry.value / totalAmount * 100);
                
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoryName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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

  List<PieChartSectionData> _getPieSections() {
    final totalAmount = _categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    
    return _categoryTotals.entries.map((entry) {
      final categoryName = entry.key;
      final color = _getCategoryColor(categoryName);
      final percentage = (entry.value / totalAmount * 100);
      
      return PieChartSectionData(
        value: entry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 50,
        color: color,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
        showTitle: percentage > 5, // Only show title if slice is large enough
      );
    }).toList();
  }

  Color _getCategoryColor(String categoryName) {
    // Try to get color from database
    if (_categoryInfo.containsKey(categoryName)) {
      return Color(_categoryInfo[categoryName]!.colorValue);
    }
    
    // Fallback colors if category not found in database
    final fallbackColors = {
      'Food & Dining': Colors.orange,
      'Transportation': Colors.blue,
      'Shopping': Colors.purple,
      'Entertainment': Colors.pink,
      'Bills & Utilities': Colors.red,
      'Healthcare': Colors.green,
      'Education': Colors.teal,
      'Travel': Colors.indigo,
      'Personal Care': Colors.deepPurple,
    };
    
    return fallbackColors[categoryName] ?? Colors.grey;
  }
}