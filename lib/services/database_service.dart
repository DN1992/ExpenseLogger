import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/expense.dart';

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
      // Get the documents directory for Linux
      Directory documentsDirectory;
      
      if (Platform.isLinux) {
        // For Linux, use a custom path in the user's home directory
        final homeDir = Platform.environment['HOME'] ?? '.';
        final appDir = Directory('$homeDir/.expense_log');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        documentsDirectory = appDir;
      } else {
        // For other platforms, use getApplicationDocumentsDirectory
        documentsDirectory = await getApplicationDocumentsDirectory();
      }
      
      String path = join(documentsDirectory.path, 'expense_database.db');
      
      print('Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          print('Creating database tables...');
          await db.execute('''
            CREATE TABLE expenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              note TEXT,
              receiptPath TEXT
            )
          ''');
          print('Database tables created successfully');
        },
        onOpen: (db) {
          print('Database opened successfully');
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
}