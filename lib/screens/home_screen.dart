import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/expense.dart';
import '../models/user_category.dart';
import '../widgets/expense_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/time_period_selector.dart';
import 'add_expense_screen.dart';
import 'category_management_screen.dart';
import 'export_config_screen.dart';
import 'summary_screen.dart';
import '../widgets/subcategory_chart.dart';
import '../screens/edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseService _databaseService;
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String? _selectedCategory;
  Map<String, Color> _categoryColors = {};
  
  // Time period filter for chart
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _refreshAllData();
  }

  Future<void> _refreshAllData() async {
    setState(() => _isLoading = true);
    try {
      // Load expenses
      final expenses = await _databaseService.getAllExpenses();
      
      // Load category colors
      final dbService = DatabaseService();
      final categories = await dbService.getAllMainCategories();
      
      final Map<String, Color> colors = {};
      for (var category in categories) {
        colors[category.name] = Color(category.colorValue);
      }
      
      setState(() {
        _allExpenses = expenses;
        _categoryColors = colors;
      });
      
      // Apply time filter
      _applyTimeFilter();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _applyTimeFilter() {
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
    
    setState(() {});
  }

  String _getPeriodLabel() {
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

  double get _totalExpenses {
    return _filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  List<String> _getUniqueCategories() {
    return _filteredExpenses.map((e) => e.category).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final uniqueCategories = _getUniqueCategories();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SummaryScreen(),
                ),
              );
            },
            tooltip: 'Summary & Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportConfigScreen(),
                ),
              );
            },
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              ).then((_) {
                _refreshAllData();
              });
            },
            tooltip: 'Manage Categories',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshAllData,
              child: CustomScrollView(
                slivers: [
                  // Total Expenses Card
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade900],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '€${_totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_filteredExpenses.length} transactions',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getPeriodLabel(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Time Period Selector for Chart
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TimePeriodSelector(
                        selectedPeriod: _selectedPeriod,
                        onPeriodChanged: (period, startDate, endDate) {
                          setState(() {
                            _selectedPeriod = period;
                            _customStartDate = startDate;
                            _customEndDate = endDate;
                          });
                          _applyTimeFilter();
                        },
                        customStartDate: _customStartDate,
                        customEndDate: _customEndDate,
                      ),
                    ),
                  ),
                  
                  // Main Category Chart (Filtered by time period)
                  if (_filteredExpenses.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ExpenseChart(expenses: _filteredExpenses),
                      ),
                    ),
                  
                  // Category Selector for Subcategory Chart
                  if (_filteredExpenses.isNotEmpty && uniqueCategories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Drill Down by Category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    hintText: 'Select a category',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('All Categories'),
                                    ),
                                    ...uniqueCategories.map((category) {
                                      final color = _categoryColors[category] ?? Colors.grey;
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Row(
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
                                            Text(category),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Subcategory Chart
                  if (_selectedCategory != null && _filteredExpenses.any((e) => e.category == _selectedCategory))
                    SliverToBoxAdapter(
                      child: SubcategoryChart(
                        expenses: _filteredExpenses,
                        category: _selectedCategory!,
                      ),
                    ),
                  
                  // Recent Transactions Header
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${_filteredExpenses.length} total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Expense List
                  ExpenseList(
                    expenses: _filteredExpenses,
                    onDelete: _deleteExpense,
                    onEdit: _editExpense, // Add this line
                    categoryColors: _categoryColors,
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseService.deleteExpense(expense.id!);
      _refreshAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
    if (result == true) {
      _refreshAllData();
    }
  }
  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expense),
      ),
    );
    if (result == true) {
      _refreshAllData();
    }
  }
}