import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/expense.dart';
import '../models/user_category.dart';
import '../models/categories.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

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

      return await openDatabase(
        path,
        version: 4, // Version 4 includes tags column
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  // This method is called when the database is created for the first time
  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');
    
    // Create expenses table
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
    
    // Create user_categories table
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
    
    // Insert default categories
    await _insertDefaultCategories(db);
    
    print('Database tables created successfully');
  }

  // This method is called when upgrading to a newer version
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      print('Adding subcategory column...');
      await db.execute('ALTER TABLE expenses ADD COLUMN subcategory TEXT');
    }
    
    if (oldVersion < 3) {
      print('Creating user_categories table...');
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
      print('Adding tags column...');
      await db.execute('ALTER TABLE expenses ADD COLUMN tags TEXT');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    print('Inserting default categories...');
    
    // First, insert all main categories
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
      print('Inserted main category: ${cat.name} with ID: $id');
    }
    
    // Now insert all subcategories for each main category
    for (var cat in defaultCategories) {
      final parentId = mainCategoryIds[cat.name];
      if (parentId != null) {
        for (var j = 0; j < cat.subcategories.length; j++) {
          final subName = cat.subcategories[j];
          try {
            final id = await db.insert('user_categories', {
              'name': subName,
              'iconName': cat.icon.toString().split('.').last,
              'colorValue': cat.color.value,
              'isCustom': 0,
              'parentId': parentId,
              'displayOrder': j,
            });
            print('Inserted subcategory: $subName under ${cat.name} with ID: $id');
          } catch (e) {
            print('Error inserting subcategory $subName: $e');
          }
        }
      }
    }
    print('Finished inserting all default categories');
  }

  // ============ Expense Methods ============
  
  Future<int> insertExpense(Expense expense) async {
    try {
      Database db = await database;
      
      // Validate expense data
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
      print('Inserting expense with data: $map');
      
      int id = await db.insert('expenses', map);
      print('Insert successful, ID: $id');
      
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
      
      print('Retrieved ${maps.length} expenses');
      
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting expenses: $e');
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

  // ============ Category Methods ============

  Future<List<UserCategory>> getAllMainCategories() async {
    try {
      Database db = await database;
      final result = await db.query(
        'user_categories',
        where: 'parentId IS NULL',
        orderBy: 'displayOrder, name',
      );
      return result.map((map) => UserCategory.fromMap(map)).toList();
    } catch (e) {
      print('Error getting main categories: $e');
      return [];
    }
  }

  Future<List<UserCategory>> getSubcategories(int parentId) async {
    try {
      Database db = await database;
      final result = await db.query(
        'user_categories',
        where: 'parentId = ?',
        whereArgs: [parentId],
        orderBy: 'displayOrder, name',
      );
      return result.map((map) => UserCategory.fromMap(map)).toList();
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
    try {
      Database db = await database;
      
      if (category.name.isEmpty) {
        throw Exception('Category name cannot be empty');
      }
      
      final map = category.toMap();
      map.remove('id'); // Remove id for auto-increment
      
      print('Inserting category with data: $map');
      
      int id = await db.insert('user_categories', map);
      print('Category inserted with ID: $id');
      
      return id;
    } catch (e) {
      print('Error inserting category: $e');
      rethrow;
    }
  }

  Future<int> updateCategory(UserCategory category) async {
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
    try {
      Database db = await database;
      // First, delete any subcategories
      await db.delete('user_categories', where: 'parentId = ?', whereArgs: [id]);
      // Then delete the main category
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
      
      // Check if any expense uses this category or subcategory
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