import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../models/user_category.dart';

class SubcategoryChart extends StatefulWidget {
  final List<Expense> expenses;
  final String category;

  const SubcategoryChart({
    super.key,
    required this.expenses,
    required this.category,
  });

  @override
  State<SubcategoryChart> createState() => _SubcategoryChartState();
}

class _SubcategoryChartState extends State<SubcategoryChart> {
  Map<String, double> _subcategoryTotals = {};
  Color _categoryColor = Colors.grey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    try {
      final dbService = DatabaseService();
      final mainCategories = await dbService.getAllMainCategories();
      
      final category = mainCategories.firstWhere(
        (c) => c.name == widget.category,
        orElse: () => UserCategory(
          name: widget.category,
          iconName: 'category',
          colorValue: Colors.grey.value,
          isCustom: false,
          displayOrder: 0,
        ),
      );
      
      setState(() {
        _categoryColor = Color(category.colorValue);
        _calculateSubcategoryTotals();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading category data: $e');
      setState(() {
        _categoryColor = Colors.grey;
        _calculateSubcategoryTotals();
        _isLoading = false;
      });
    }
  }

  void _calculateSubcategoryTotals() {
    Map<String, double> totals = {};
    
    final categoryExpenses = widget.expenses.where((e) => e.category == widget.category);
    
    for (var expense in categoryExpenses) {
      String key = expense.subcategory ?? 'Uncategorized';
      totals[key] = (totals[key] ?? 0) + expense.amount;
    }
    
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _subcategoryTotals = Map.fromEntries(sortedEntries);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_subcategoryTotals.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No subcategory data for ${widget.category}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add expenses with subcategories to see breakdown',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalAmount = _subcategoryTotals.values.fold(0.0, (a, b) => a + b);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category name and color indicator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.category} - Subcategory Breakdown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: €${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            
            // Pie chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getPieSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Legend and amounts
            ..._subcategoryTotals.entries.map((entry) {
              final percentage = (entry.value / totalAmount * 100);
              final colorIndex = _subcategoryTotals.keys.toList().indexOf(entry.key);
              final sectionColor = _getSubcategoryColor(colorIndex);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sectionColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: sectionColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '€${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sectionColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections() {
    final totalAmount = _subcategoryTotals.values.fold(0.0, (a, b) => a + b);
    
    return _subcategoryTotals.entries.map((entry) {
      final percentage = (entry.value / totalAmount * 100);
      final index = _subcategoryTotals.keys.toList().indexOf(entry.key);
      final color = _getSubcategoryColor(index);
      
      return PieChartSectionData(
        value: entry.value,
        title: percentage > 8 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 50,
        color: color,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
        showTitle: percentage > 8,
      );
    }).toList();
  }

  Color _getSubcategoryColor(int index) {
    final hsl = HSLColor.fromColor(_categoryColor);
    final lightness = (0.35 + (index * 0.08)).clamp(0.35, 0.75);
    final saturation = (0.55 + (index * 0.05)).clamp(0.55, 0.85);
    return hsl.withLightness(lightness).withSaturation(saturation).toColor();
  }
}