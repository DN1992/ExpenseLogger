import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/user_category.dart';
import '../services/database_service.dart';
import '../widgets/tag_input.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  List<UserCategory> _mainCategories = [];
  Map<int, List<UserCategory>> _subcategories = {};
  String? _selectedCategory;
  String? _selectedSubcategory;
  DateTime _selectedDate = DateTime.now();
  List<String> _tags = [];
  bool _isSaving = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final dbService = DatabaseService();
      _mainCategories = await dbService.getAllMainCategories();
      
      // Set default selected category if available
      if (_mainCategories.isNotEmpty && _selectedCategory == null) {
        _selectedCategory = _mainCategories.first.name;
      }
      
      // Load subcategories for each main category
      for (var category in _mainCategories) {
        final subs = await dbService.getSubcategories(category.id!);
        _subcategories[category.id!] = subs;
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  Future<List<String>> _getSuggestedTags() async {
    try {
      final dbService = DatabaseService();
      final expenses = await dbService.getAllExpenses();
      final allTags = <String>{};
      for (var expense in expenses) {
        allTags.addAll(expense.tags);
      }
      return allTags.toList()..sort();
    } catch (e) {
      print('Error getting suggested tags: $e');
      return [];
    }
  }

  List<UserCategory> _getCurrentSubcategories() {
    if (_selectedCategory == null) return [];
    final currentCategory = _mainCategories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => _mainCategories.isNotEmpty 
          ? _mainCategories.first 
          : UserCategory(
              name: '',
              iconName: 'category',
              colorValue: Colors.grey.value,
              isCustom: false,
              displayOrder: 0,
            ),
    );
    return _subcategories[currentCategory.id] ?? [];
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'directions_car': return Icons.directions_car;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'movie': return Icons.movie;
      case 'receipt': return Icons.receipt;
      case 'local_hospital': return Icons.local_hospital;
      case 'school': return Icons.school;
      case 'flight': return Icons.flight;
      case 'face': return Icons.face;
      case 'category': return Icons.category;
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'pets': return Icons.pets;
      case 'sports': return Icons.sports;
      case 'music_note': return Icons.music_note;
      case 'book': return Icons.book;
      case 'phone_android': return Icons.phone_android;
      case 'pool': return Icons.pool;
      case 'fitness_center': return Icons.fitness_center;
      case 'brush': return Icons.brush;
      case 'cake': return Icons.cake;
      case 'coffee': return Icons.coffee;
      case 'wine_bar': return Icons.wine_bar;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = _getCurrentSubcategories();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: _isSaving || _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'What did you spend on?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Main Category Dropdown
                  if (_mainCategories.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          hint: const Text('Select Category'),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: _mainCategories.map((category) {
                            return DropdownMenuItem(
                              value: category.name,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Color(category.colorValue),
                                    child: Icon(
                                      _getIconData(category.iconName),
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _selectedSubcategory = null;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Subcategory Dropdown
                  if (subcategories.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubcategory,
                          hint: const Text('Select Subcategory (Optional)'),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('None'),
                            ),
                            ...subcategories.map((sub) {
                              return DropdownMenuItem(
                                value: sub.name,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIconData(sub.iconName),
                                      size: 16,
                                      color: Color(sub.colorValue),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(sub.name),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSubcategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Show message if no categories
                  if (_mainCategories.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'No categories found',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please add categories in the Category Management screen first',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Date Picker
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: _selectDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags Section
                  FutureBuilder<List<String>>(
                    future: _getSuggestedTags(),
                    builder: (context, snapshot) {
                      final suggestedTags = snapshot.data ?? [];
                      return TagInput(
                        tags: _tags,
                        onTagsChanged: (newTags) {
                          setState(() {
                            _tags = newTags;
                          });
                        },
                        suggestedTags: suggestedTags,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _mainCategories.isEmpty ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Save Expense'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        double amount = double.parse(_amountController.text.trim());
        
        final expense = Expense(
          title: _titleController.text.trim(),
          amount: amount,
          category: _selectedCategory ?? _mainCategories.first.name,
          subcategory: _selectedSubcategory,
          date: _selectedDate,
          note: null, // No note
          tags: _tags,
        );

        print('Saving expense: ${expense.title}, Category: ${expense.category}, Tags: ${expense.tags}');

        final databaseService = DatabaseService();
        final id = await databaseService.insertExpense(expense);
        
        if (id > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to save expense');
        }
      } catch (e) {
        print('Error saving expense: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving expense: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}