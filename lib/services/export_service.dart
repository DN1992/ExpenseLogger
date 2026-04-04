import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export expenses to CSV file with date range
  Future<File?> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get expenses based on date range
      final dbService = DatabaseService();
      List<Expense> expenses;
      
      if (startDate != null && endDate != null) {
        expenses = await dbService.getExpensesByDateRange(startDate, endDate);
      } else {
        expenses = await dbService.getAllExpenses();
      }
      
      if (expenses.isEmpty) {
        throw Exception('No expenses to export in the selected date range');
      }

      // Create CSV content
      StringBuffer csvBuffer = StringBuffer();
      
      // Write headers
      csvBuffer.writeln('ID,Title,Amount,Category,Subcategory,Date,Tags');
      
      // Write data rows
      for (var expense in expenses) {
        // Escape commas and quotes in fields
        String title = _escapeCSV(expense.title);
        String category = _escapeCSV(expense.category);
        String subcategory = _escapeCSV(expense.subcategory ?? '');
        String tags = _escapeCSV(expense.tags.join('; '));
        
        csvBuffer.writeln(
          '${expense.id ?? ''},'
          '$title,'
          '${expense.amount.toStringAsFixed(2)},'
          '$category,'
          '$subcategory,'
          '${_formatDate(expense.date)},'
          '$tags'
        );
      }

      // Get download directory
      final file = await _saveFile(csvBuffer.toString(), 'csv', startDate, endDate);
      return file;
      
    } catch (e) {
      print('Error exporting to CSV: $e');
      rethrow;
    }
  }

  /// Export expenses to JSON file with date range
  Future<File?> exportToJSON({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get expenses based on date range
      final dbService = DatabaseService();
      List<Expense> expenses;
      
      if (startDate != null && endDate != null) {
        expenses = await dbService.getExpensesByDateRange(startDate, endDate);
      } else {
        expenses = await dbService.getAllExpenses();
      }
      
      if (expenses.isEmpty) {
        throw Exception('No expenses to export in the selected date range');
      }

      // Convert expenses to JSON-serializable maps
      final List<Map<String, dynamic>> jsonList = expenses.map((e) {
        return {
          'id': e.id,
          'title': e.title,
          'amount': e.amount,
          'category': e.category,
          'subcategory': e.subcategory,
          'date': e.date.toIso8601String(),
          'tags': e.tags,
        };
      }).toList();

      // Encode to JSON with pretty formatting
      String jsonString = JsonEncoder.withIndent('  ').convert(jsonList);

      // Get download directory
      final file = await _saveFile(jsonString, 'json', startDate, endDate);
      return file;
      
    } catch (e) {
      print('Error exporting to JSON: $e');
      rethrow;
    }
  }

  /// Get summary statistics for export
  Future<Map<String, dynamic>> getExportSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dbService = DatabaseService();
    List<Expense> expenses;
    
    if (startDate != null && endDate != null) {
      expenses = await dbService.getExpensesByDateRange(startDate, endDate);
    } else {
      expenses = await dbService.getAllExpenses();
    }
    
    if (expenses.isEmpty) {
      return {
        'count': 0,
        'total': 0.0,
        'categories': {},
      };
    }
    
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final categories = <String, double>{};
    
    for (var expense in expenses) {
      categories[expense.category] = (categories[expense.category] ?? 0) + expense.amount;
    }
    
    return {
      'count': expenses.length,
      'total': total,
      'categories': categories,
    };
  }

  Future<File> _saveFile(String content, String format, DateTime? startDate, DateTime? endDate) async {
    // Get download directory
    Directory? downloadDir;
    
    if (Platform.isLinux) {
      final homeDir = Platform.environment['HOME'] ?? '.';
      downloadDir = Directory('$homeDir/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
    } else if (Platform.isAndroid) {
      downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        downloadDir = await getApplicationDocumentsDirectory();
      }
    } else {
      downloadDir = await getApplicationDocumentsDirectory();
    }

    // Create filename with date range
    String dateRangeStr;
    if (startDate != null && endDate != null) {
      dateRangeStr = '${_formatDateForFilename(startDate)}_to_${_formatDateForFilename(endDate)}';
    } else {
      dateRangeStr = 'all_time';
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expenses_${dateRangeStr}_$timestamp.$format';
    final filePath = '${downloadDir.path}/$fileName';
    
    // Write file
    final file = File(filePath);
    await file.writeAsString(content);
    
    print('File exported to: $filePath');
    return file;
  }

  String _escapeCSV(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  String _formatDateForFilename(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}