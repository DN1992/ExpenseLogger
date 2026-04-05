import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/user_category.dart';
import '../models/categories.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  
  // Cache for categories to avoid repeated DB queries
  List<UserCategory> _cachedMainCategories = [];
  Map<int, List<UserCategory>> _cachedSubcategories = {};
  Map<String, Color> _cachedCategoryColors = {};
  DateTime? _lastCategoryCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory;
      
      if (Platform.isLinux) {
        final homeDir = Platform.environment['HOME'] ?? '.';
        final appDir = Directory('$homeDir/.expense_log');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        documentsDirectory = appDir;
      } else {
        documentsDirectory = await getApplicationDocumentsDirectory();
      }
      
      String path = join(documentsDirectory.path, 'expense_database.db');
      
      print('Database path: $path');

      // Don't initialize databaseFactory here - it's already done in main.dart
      return await openDatabase(
        path,
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        singleInstance: true,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');
    
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        subcategory TEXT,
        date TEXT NOT NULL,
        note TEXT,
        receiptPath TEXT,
        tags TEXT
      )
    ''');
    
    // Add indexes for faster queries
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
    await db.execute('CREATE INDEX idx_expenses_date_category ON expenses(date, category)');
    
    await db.execute('''
      CREATE TABLE user_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        iconName TEXT,
        colorValue INTEGER NOT NULL,
        isCustom INTEGER NOT NULL DEFAULT 1,
        parentId INTEGER,
        displayOrder INTEGER DEFAULT 0,
        FOREIGN KEY(parentId) REFERENCES user_categories(id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('CREATE INDEX idx_categories_parent ON user_categories(parentId)');
    await db.execute('CREATE INDEX idx_categories_order ON user_categories(displayOrder)');
    
    await _insertDefaultCategories(db);
    print('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE expenses ADD COLUMN subcategory TEXT');
    }
    
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE user_categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          iconName TEXT,
          colorValue INTEGER NOT NULL,
          isCustom INTEGER NOT NULL DEFAULT 1,
          parentId INTEGER,
          displayOrder INTEGER DEFAULT 0,
          FOREIGN KEY(parentId) REFERENCES user_categories(id) ON DELETE CASCADE
        )
      ''');
      await _insertDefaultCategories(db);
    }
    
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE expenses ADD COLUMN tags TEXT');
      // Add indexes
      await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
      await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    print('Inserting default categories...');
    
    Map<String, int> mainCategoryIds = {};
    
    for (var i = 0; i < defaultCategories.length; i++) {
      final cat = defaultCategories[i];
      final id = await db.insert('user_categories', {
        'name': cat.name,
        'iconName': cat.icon.toString().split('.').last,
        'colorValue': cat.color.value,
        'isCustom': 0,
        'parentId': null,
        'displayOrder': i,
      });
      mainCategoryIds[cat.name] = id;
    }
    
    for (var cat in defaultCategories) {
      final parentId = mainCategoryIds[cat.name];
      if (parentId != null) {
        for (var j = 0; j < cat.subcategories.length; j++) {
          final subName = cat.subcategories[j];
          await db.insert('user_categories', {
            'name': subName,
            'iconName': cat.icon.toString().split('.').last,
            'colorValue': cat.color.value,
            'isCustom': 0,
            'parentId': parentId,
            'displayOrder': j,
          });
        }
      }
    }
    print('Finished inserting all default categories');
  }

  // ============ Expense Methods ============
  
  Future<int> insertExpense(Expense expense) async {
    try {
      Database db = await database;
      
      if (expense.title.isEmpty) {
        throw Exception('Title cannot be empty');
      }
      if (expense.amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }
      if (expense.category.isEmpty) {
        throw Exception('Category cannot be empty');
      }

      final map = expense.toMap();
      int id = await db.insert('expenses', map);
      return id;
    } catch (e) {
      print('Error in insertExpense: $e');
      rethrow;
    }
  }

  Future<List<Expense>> getAllExpenses() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'date DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting expenses: $e');
      return [];
    }
  }

  // Paginated query for better performance
  Future<List<Expense>> getExpensesPaginated({int limit = 30, int offset = 0}) async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );
      
      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    } catch (e) {
      print('Error getting paginated expenses: $e');
      return [];
    }
  }

  Future<Expense?> getExpense(int id) async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Expense.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting expense: $e');
      return null;
    }
  }

  Future<int> updateExpense(Expense expense) async {
    try {
      Database db = await database;
      return await db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  Future<int> deleteExpense(int id) async {
    try {
      Database db = await database;
      return await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'date DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting expenses by date range: $e');
      return [];
    }
  }

  Future<Map<String, double>> getCategoryTotals() async {
    try {
      Database db = await database;
      final result = await db.rawQuery('''
        SELECT category, SUM(amount) as total 
        FROM expenses 
        GROUP BY category
      ''');
      
      Map<String, double> totals = {};
      for (var row in result) {
        totals[row['category'] as String] = row['total'] as double;
      }
      return totals;
    } catch (e) {
      print('Error getting category totals: $e');
      return {};
    }
  }

  // ============ Category Methods with Caching ============

  void _clearCategoryCache() {
    _cachedMainCategories = [];
    _cachedSubcategories.clear();
    _cachedCategoryColors.clear();
    _lastCategoryCacheTime = null;
  }

  Future<List<UserCategory>> getAllMainCategories({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && 
          _cachedMainCategories.isNotEmpty && 
          _lastCategoryCacheTime != null &&
          DateTime.now().difference(_lastCategoryCacheTime!) < _cacheDuration) {
        return _cachedMainCategories;
      }
      
      Database db = await database;
      final result = await db.query(
        'user_categories',
        where: 'parentId IS NULL',
        orderBy: 'displayOrder, name',
      );
      
      _cachedMainCategories = result.map((map) => UserCategory.fromMap(map)).toList();
      _lastCategoryCacheTime = DateTime.now();
      return _cachedMainCategories;
    } catch (e) {
      print('Error getting main categories: $e');
      return [];
    }
  }

  Future<List<UserCategory>> getSubcategories(int parentId) async {
    try {
      if (_cachedSubcategories.containsKey(parentId)) {
        return _cachedSubcategories[parentId]!;
      }
      
      Database db = await database;
      final result = await db.query(
        'user_categories',
        where: 'parentId = ?',
        whereArgs: [parentId],
        orderBy: 'displayOrder, name',
      );
      
      final subs = result.map((map) => UserCategory.fromMap(map)).toList();
      _cachedSubcategories[parentId] = subs;
      return subs;
    } catch (e) {
      print('Error getting subcategories: $e');
      return [];
    }
  }

  Future<UserCategory?> getCategoryById(int id) async {
    try {
      Database db = await database;
      final result = await db.query(
        'user_categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return UserCategory.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error getting category by id: $e');
      return null;
    }
  }

  Future<int> insertCategory(UserCategory category) async {
    _clearCategoryCache();
    try {
      Database db = await database;
      
      if (category.name.isEmpty) {
        throw Exception('Category name cannot be empty');
      }
      
      final map = category.toMap();
      map.remove('id');
      
      int id = await db.insert('user_categories', map);
      return id;
    } catch (e) {
      print('Error inserting category: $e');
      rethrow;
    }
  }

  Future<int> updateCategory(UserCategory category) async {
    _clearCategoryCache();
    try {
      Database db = await database;
      return await db.update(
        'user_categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<int> deleteCategory(int id) async {
    _clearCategoryCache();
    try {
      Database db = await database;
      await db.delete('user_categories', where: 'parentId = ?', whereArgs: [id]);
      return await db.delete('user_categories', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  Future<bool> isCategoryInUse(int categoryId) async {
    try {
      Database db = await database;
      final category = await getCategoryById(categoryId);
      if (category == null) return false;
      
      final result = await db.query(
        'expenses',
        where: 'category = ? OR subcategory = ?',
        whereArgs: [category.name, category.name],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if category is in use: $e');
      return false;
    }
  }
}