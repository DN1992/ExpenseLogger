import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  String? _receiptPath;
  bool _isSaving = false;

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
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
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _receiptPath != null
                                      ? 'Receipt attached'
                                      : 'No receipt',
                                  style: TextStyle(
                                    color: _receiptPath != null
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: _takePhoto,
                                tooltip: 'Take photo',
                              ),
                              IconButton(
                                icon: const Icon(Icons.photo_library),
                                onPressed: _pickImage,
                                tooltip: 'Choose from gallery',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveExpense,
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

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _receiptPath = image.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _receiptPath = image.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Parse amount with proper decimal handling
        double amount = double.parse(_amountController.text.trim());
        
        // Create expense object
        final expense = Expense(
          title: _titleController.text.trim(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: _noteController.text.isNotEmpty ? _noteController.text.trim() : null,
          receiptPath: _receiptPath,
        );

        print('Saving expense: ${expense.title}, Amount: ${expense.amount}'); // Debug log

        final databaseService = DatabaseService();
        final id = await databaseService.insertExpense(expense);
        
        print('Expense saved with ID: $id'); // Debug log
        
        if (id > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to save expense - returned ID: $id');
        }
      } catch (e) {
        print('Error saving expense: $e'); // Debug log
        print('Stack trace: ${StackTrace.current}'); // Debug log
        
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
    _noteController.dispose();
    super.dispose();
  }
}