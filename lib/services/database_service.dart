import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'expense_database.db');
      
      return await openDatabase(
        path,
        version: 2, // Increment version number
        onCreate: (Database db, int version) async {
          // Create new database with subcategory column
          await db.execute('''
            CREATE TABLE expenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              subcategory TEXT,
              date TEXT NOT NULL,
              note TEXT,
              receiptPath TEXT
            )
          ''');
          
          // New categories table
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
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            // Add subcategory column to existing table
            await db.execute('ALTER TABLE expenses ADD COLUMN subcategory TEXT');
          }
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }


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
      print('Inserting expense with data: $map'); // Debug log
      
      int id = await db.insert('expenses', map);
      print('Insert successful, ID: $id'); // Debug log
      
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
      
      print('Retrieved ${maps.length} expenses'); // Debug log
      
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
  Future<void> _insertDefaultCategories(Database db) async {
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
  }
  
  // Now insert all subcategories for each main category
  for (var cat in defaultCategories) {
    final parentId = mainCategoryIds[cat.name];
    if (parentId != null) {
      for (var j = 0; j < cat.subcategories.length; j++) {
        final subName = cat.subcategories[j];
        await db.insert('user_categories', {
          'name': subName,
          'iconName': cat.icon.toString().split('.').last, // Inherit parent icon
          'colorValue': cat.color.value, // Inherit parent color
          'isCustom': 0,
          'parentId': parentId,
          'displayOrder': j,
        });
      }
    }
  }
}

Future<List<UserCategory>> getAllMainCategories() async {
  Database db = await database;
  final result = await db.query(
    'user_categories',
    where: 'parentId IS NULL',
    orderBy: 'displayOrder, name',
  );
  return result.map((map) => UserCategory.fromMap(map)).toList();
}

Future<List<UserCategory>> getSubcategories(int parentId) async {
  Database db = await database;
  final result = await db.query(
    'user_categories',
    where: 'parentId = ?',
    whereArgs: [parentId],
    orderBy: 'displayOrder, name',
  );
  return result.map((map) => UserCategory.fromMap(map)).toList();
}

Future<UserCategory?> getCategoryById(int id) async {
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
}

Future<int> insertCategory(UserCategory category) async {
  try {
    Database db = await database;
    
    // Validate required fields
    if (category.name.isEmpty) {
      throw Exception('Category name cannot be empty');
    }
    
    final map = category.toMap();
    // Remove id if it's null (for auto-increment)
    map.remove('id');
    
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
  Database db = await database;
  return await db.update(
    'user_categories',
    category.toMap(),
    where: 'id = ?',
    whereArgs: [category.id],
  );
}

Future<int> deleteCategory(int id) async {
  Database db = await database;
  // First, delete any subcategories
  await db.delete('user_categories', where: 'parentId = ?', whereArgs: [id]);
  // Then delete the main category
  return await db.delete('user_categories', where: 'id = ?', whereArgs: [id]);
}

Future<bool> isCategoryInUse(int categoryId) async {
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
}

}