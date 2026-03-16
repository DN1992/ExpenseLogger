import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/user_category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<UserCategory> _mainCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();
      _mainCategories = await dbService.getAllMainCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can add, edit, or delete custom categories. Default categories cannot be deleted if they have expenses.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Category list
                Expanded(
                  child: ListView.builder(
                    itemCount: _mainCategories.length,
                    itemBuilder: (context, index) {
                      final category = _mainCategories[index];
                      return _buildCategoryTile(category);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildCategoryTile(UserCategory category) {
    return FutureBuilder<List<UserCategory>>(
      future: DatabaseService().getSubcategories(category.id!),
      builder: (context, snapshot) {
        final subcategories = snapshot.data ?? [];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(category.colorValue),
                  child: Icon(
                    _getIconData(category.iconName),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(category.isCustom ? 'Custom' : 'Default'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditCategoryDialog(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _deleteCategory(category),
                    ),
                  ],
                ),
              ),
              
              // Subcategories
              if (subcategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
                  child: Column(
                    children: subcategories.map((sub) {
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getIconData(sub.iconName),
                          size: 16,
                          color: Color(sub.colorValue),
                        ),
                        title: Text(sub.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _showEditCategoryDialog(sub, parentId: category.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => _deleteCategory(sub),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
              // Add subcategory button
              Padding(
                padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
                child: TextButton.icon(
                  onPressed: () => _showAddSubcategoryDialog(category.id!),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subcategory'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;
    int colorValue = Colors.blue.value;
    String iconName = 'category';
    bool isSaving = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Category'),
            content: Container(
              width: double.maxFinite, // Constrain width
              constraints: const BoxConstraints(maxHeight: 500), // Constrain height
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category name input
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Hobbies, Pets, etc.',
                        prefixIcon: Icon(Icons.title),
                      ),
                      autofocus: true,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 20),
                    
                    // Color picker section
                    const Text(
                      'Choose Color:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Colors.red,
                          Colors.pink,
                          Colors.purple,
                          Colors.deepPurple,
                          Colors.indigo,
                          Colors.blue,
                          Colors.lightBlue,
                          Colors.cyan,
                          Colors.teal,
                          Colors.green,
                          Colors.lightGreen,
                          Colors.lime,
                          Colors.yellow,
                          Colors.amber,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.brown,
                          Colors.grey,
                          Colors.blueGrey,
                          Colors.black,
                        ].map((color) {
                          return GestureDetector(
                            onTap: isSaving ? null : () {
                              setState(() {
                                selectedColor = color;
                                colorValue = color.value;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selectedColor == color
                                    ? Border.all(color: Colors.black, width: 3)
                                    : null,
                                boxShadow: selectedColor == color
                                    ? [BoxShadow(color: Colors.black26, blurRadius: 4)]
                                    : null,
                              ),
                              child: selectedColor == color
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Icon picker section
                    const Text(
                      'Choose Icon:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: GridView.count(
                        crossAxisCount: 5,
                        shrinkWrap: true,
                        childAspectRatio: 1,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          Icons.restaurant,
                          Icons.shopping_cart,
                          Icons.directions_car,
                          Icons.local_gas_station,
                          Icons.shopping_bag,
                          Icons.movie,
                          Icons.receipt,
                          Icons.local_hospital,
                          Icons.school,
                          Icons.flight,
                          Icons.face,
                          Icons.category,
                          Icons.home,
                          Icons.work,
                          Icons.pets,
                          Icons.sports,
                          Icons.music_note,
                          Icons.book,
                          Icons.phone_android,
                          Icons.pool,
                          Icons.fitness_center,
                          Icons.brush,
                          Icons.cake,
                          Icons.coffee,
                          Icons.wine_bar,
                        ].map((icon) {
                          return IconButton(
                            icon: Icon(icon),
                            color: selectedIcon == icon ? Colors.blue : Colors.grey,
                            iconSize: 28,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: isSaving ? null : () {
                              setState(() {
                                selectedIcon = icon;
                                iconName = icon.toString().split('.').last;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    
                    if (isSaving) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a category name'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    isSaving = true;
                  });

                  try {
                    final newCategory = UserCategory(
                      name: nameController.text.trim(),
                      iconName: iconName,
                      colorValue: colorValue,
                      isCustom: true,
                      displayOrder: _mainCategories.length,
                    );
                    
                    print('Saving new category: ${newCategory.name}');
                    final id = await DatabaseService().insertCategory(newCategory);
                    print('Category saved with ID: $id');
                    
                    if (mounted) {
                      Navigator.pop(context);
                      await _loadCategories(); // Refresh the list
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Category "${nameController.text}" added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error saving category: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding category: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        isSaving = false;
                      });
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddSubcategoryDialog(int parentId) async {
    final nameController = TextEditingController();
    final parent = await DatabaseService().getCategoryById(parentId);
    bool isSaving = false;
    
    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Subcategory'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parent: ${parent?.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Weekend Trip',
                    prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  ),
                  autofocus: true,
                  enabled: !isSaving,
                ),
                if (isSaving) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a subcategory name'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    isSaving = true;
                  });

                  try {
                    final subcategories = await DatabaseService().getSubcategories(parentId);
                    final newSubcategory = UserCategory(
                      name: nameController.text.trim(),
                      iconName: parent?.iconName ?? 'category',
                      colorValue: parent?.colorValue ?? Colors.blue.value,
                      isCustom: true,
                      parentId: parentId,
                      displayOrder: subcategories.length,
                    );
                    
                    await DatabaseService().insertCategory(newSubcategory);
                    
                    if (mounted) {
                      Navigator.pop(context);
                      _loadCategories();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Subcategory "${nameController.text}" added'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditCategoryDialog(UserCategory category, {int? parentId}) async {
    final nameController = TextEditingController(text: category.name);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${parentId != null ? 'Sub' : ''}Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                category.name = nameController.text;
                await DatabaseService().updateCategory(category);
                if (mounted) {
                  Navigator.pop(context);
                  _loadCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  } // _showEditCategoryDialog

  Future<void> _deleteCategory(UserCategory category) async {
    final inUse = await DatabaseService().isCategoryInUse(category.id!);
    
    if (inUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete category that has expenses'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${category.parentId != null ? 'Sub' : ''}Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().deleteCategory(category.id!);
      _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    }
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
      default: return Icons.category;
    }
  }
}