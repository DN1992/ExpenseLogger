import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../widgets/time_period_selector.dart';
import '../widgets/expense_chart.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Statistics
  double _totalExpenses = 0;
  double _averagePerDay = 0;
  double _averagePerTransaction = 0;
  int _transactionCount = 0;
  double _highestExpense = 0;
  String _highestExpenseTitle = '';
  Map<String, double> _categoryTotals = {};
  Map<String, int> _tagFrequency = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();
      _allExpenses = await dbService.getAllExpenses();
      _applyFilter();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    DateTime startDate;
    DateTime endDate = DateTime.now();
    
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        endDate = startDate.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        break;
      case TimePeriod.weekly:
        startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        break;
      case TimePeriod.monthly:
        startDate = DateTime(endDate.year, endDate.month, 1);
        endDate = DateTime(endDate.year, endDate.month + 1, 0);
        break;
      case TimePeriod.yearly:
        startDate = DateTime(endDate.year, 1, 1);
        endDate = DateTime(endDate.year, 12, 31);
        break;
      case TimePeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          endDate = _customEndDate!;
        } else {
          startDate = DateTime(2020, 1, 1);
        }
        break;
    }
    
    _filteredExpenses = _allExpenses.where((e) {
      return e.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
             e.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
    
    _calculateStatistics();
  }

  void _calculateStatistics() {
    if (_filteredExpenses.isEmpty) {
      setState(() {
        _totalExpenses = 0;
        _averagePerDay = 0;
        _averagePerTransaction = 0;
        _transactionCount = 0;
        _highestExpense = 0;
        _highestExpenseTitle = '';
        _categoryTotals = {};
        _tagFrequency = {};
      });
      return;
    }
    
    _transactionCount = _filteredExpenses.length;
    _totalExpenses = _filteredExpenses.fold(0, (sum, e) => sum + e.amount);
    _averagePerTransaction = _totalExpenses / _transactionCount;
    
    // Calculate average per day
    final dateRange = _getDateRange();
    final days = dateRange['days'] ?? 1;
    _averagePerDay = _totalExpenses / days;
    
    // Find highest expense
    final highest = _filteredExpenses.reduce((a, b) => a.amount > b.amount ? a : b);
    _highestExpense = highest.amount;
    _highestExpenseTitle = highest.title;
    
    // Calculate category totals
    _categoryTotals = {};
    for (var expense in _filteredExpenses) {
      _categoryTotals[expense.category] = (_categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    // Calculate tag frequency
    _tagFrequency = {};
    for (var expense in _filteredExpenses) {
      for (var tag in expense.tags) {
        _tagFrequency[tag] = (_tagFrequency[tag] ?? 0) + 1;
      }
    }
    
    setState(() {});
  }

  Map<String, dynamic> _getDateRange() {
    if (_filteredExpenses.isEmpty) return {'days': 1};
    
    final dates = _filteredExpenses.map((e) => e.date);
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final days = maxDate.difference(minDate).inDays + 1;
    
    return {
      'start': minDate,
      'end': maxDate,
      'days': days,
    };
  }

  String _formatPeriodLabel() {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return DateFormat('MMMM dd, yyyy').format(DateTime.now());
      case TimePeriod.weekly:
        final start = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
      case TimePeriod.monthly:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case TimePeriod.yearly:
        return DateFormat('yyyy').format(DateTime.now());
      case TimePeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}';
        }
        return 'Custom Range';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Time Period Selector
                    TimePeriodSelector(
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: (period, startDate, endDate) {
                        setState(() {
                          _selectedPeriod = period;
                          _customStartDate = startDate;
                          _customEndDate = endDate;
                        });
                        _applyFilter();
                      },
                      customStartDate: _customStartDate,
                      customEndDate: _customEndDate,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Period Label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _formatPeriodLabel(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Summary Cards
                    if (_filteredExpenses.isNotEmpty) ...[
                      // Total Expenses Card
                      _buildSummaryCard(
                        title: 'Total Expenses',
                        value: '€${_totalExpenses.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        subtitle: '$_transactionCount transactions',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Average/Day',
                              value: '€${_averagePerDay.toStringAsFixed(2)}',
                              icon: Icons.calendar_today,
                              color: Colors.blue,
                              small: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Average/Transaction',
                              value: '€${_averagePerTransaction.toStringAsFixed(2)}',
                              icon: Icons.receipt,
                              color: Colors.orange,
                              small: true,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildSummaryCard(
                        title: 'Highest Expense',
                        value: '€${_highestExpense.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        color: Colors.red,
                        subtitle: _highestExpenseTitle,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Category Chart
                    if (_filteredExpenses.isNotEmpty)
                      ExpenseChart(expenses: _filteredExpenses),
                    
                    const SizedBox(height: 16),
                    
                    // Category Breakdown List
                    if (_categoryTotals.isNotEmpty)
                      _buildCategoryBreakdown(),
                    
                    const SizedBox(height: 16),
                    
                    // Tag Analysis
                    if (_tagFrequency.isNotEmpty)
                      _buildTagAnalysis(),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool small = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(small ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: small ? 20 : 24, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: small ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: small ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final sortedEntries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _totalExpenses;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...sortedEntries.map((entry) {
              final percentage = (entry.value / total * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '€${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '(${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: _getCategoryColor(entry.key),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
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

  Widget _buildTagAnalysis() {
    final sortedTags = _tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tag Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedTags.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (sortedTags.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No tags used in this period'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
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
    return colors[category] ?? Colors.grey;
  }
}