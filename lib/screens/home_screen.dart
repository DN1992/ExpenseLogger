import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/expense.dart';
import '../models/user_category.dart';
import '../widgets/expense_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/subcategory_chart.dart';
import 'add_expense_screen.dart';
import 'category_management_screen.dart';
import 'export_screen.dart';
import 'export_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseService _databaseService;
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _selectedCategory;
  Map<String, Color> _categoryColors = {}; // Add this

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _loadExpenses();
    _loadCategoryColors();
  }

  Future<void> _loadCategoryColors() async {
    try {
      final dbService = DatabaseService();
      final categories = await dbService.getAllMainCategories();
      
      final Map<String, Color> colors = {};
      for (var category in categories) {
        colors[category.name] = Color(category.colorValue);
      }
      
      setState(() {
        _categoryColors = colors;
      });
    } catch (e) {
      print('Error loading category colors: $e');
      // Set default colors if loading fails
      setState(() {
        _categoryColors = {
          'Food & Dining': Colors.orange,
          'Transportation': Colors.blue,
          'Shopping': Colors.purple,
          'Entertainment': Colors.pink,
          'Bills & Utilities': Colors.red,
          'Healthcare': Colors.green,
          'Education': Colors.teal,
          'Travel': Colors.indigo,
          'Personal Care': Colors.deepPurple,
          'Other': Colors.grey,
        };
      });
    }
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      // Load expenses
      final expenses = await _databaseService.getAllExpenses();
      
      // Load category colors (important for chart colors)
      await _loadCategoryColors();
      
      setState(() {
        _expenses = expenses;
        _isLoading = false;
        // Reset selected category if it no longer exists
        if (_selectedCategory != null && 
            !_expenses.any((e) => e.category == _selectedCategory)) {
          _selectedCategory = null;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading expenses: $e')),
      );
    }
  }

  double get _totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  List<String> _getUniqueCategories() {
    return _expenses.map((e) => e.category).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final uniqueCategories = _getUniqueCategories();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Log'),
        actions: [
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
                _loadExpenses();
                _loadCategoryColors(); // Reload colors when returning
              });
            },
            tooltip: 'Manage Categories',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpenses,
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
                            '\$${_totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_expenses.length} transactions',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Main Category Chart
                  if (_expenses.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ExpenseChart(expenses: _expenses),
                      ),
                    ),
                  
                  // Category Selector for Subcategory Chart
                  if (_expenses.isNotEmpty && uniqueCategories.isNotEmpty)
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
                  if (_selectedCategory != null && _expenses.any((e) => e.category == _selectedCategory))
                    SliverToBoxAdapter(
                      child: SubcategoryChart(
                        expenses: _expenses,
                        category: _selectedCategory!,
                      ),
                    ),
                  
                  // Recent Transactions Header
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  
                  // Expense List - Pass category colors here
                  ExpenseList(
                    expenses: _expenses,
                    onDelete: _deleteExpense,
                    categoryColors: _categoryColors, // Pass the colors map
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
      _loadExpenses();
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
      _loadExpenses();
      _loadCategoryColors();
    }
  }
}