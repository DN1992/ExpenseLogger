import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export expenses to CSV file
  Future<File?> exportToCSV() async {
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Get all expenses
      final dbService = DatabaseService();
      final expenses = await dbService.getAllExpenses();
      
      if (expenses.isEmpty) {
        throw Exception('No expenses to export');
      }

      // Create CSV content
      StringBuffer csvBuffer = StringBuffer();
      
      // Write headers
      csvBuffer.writeln('ID,Title,Amount,Category,Subcategory,Date,Note,Receipt Path');
      
      // Write data rows
      for (var expense in expenses) {
        // Escape commas and quotes in fields
        String title = _escapeCSV(expense.title);
        String category = _escapeCSV(expense.category);
        String subcategory = _escapeCSV(expense.subcategory ?? '');
        String note = _escapeCSV(expense.note ?? '');
        String receiptPath = _escapeCSV(expense.receiptPath ?? '');
        
        csvBuffer.writeln(
          '${expense.id ?? ''},'
          '$title,'
          '${expense.amount.toStringAsFixed(2)},'
          '$category,'
          '$subcategory,'
          '${_formatDate(expense.date)},'
          '$note,'
          '$receiptPath'
        );
      }

      // Get download directory
      Directory? downloadDir;
      
      if (Platform.isLinux) {
        // Linux: use ~/Downloads
        final homeDir = Platform.environment['HOME'] ?? '.';
        downloadDir = Directory('$homeDir/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      } else if (Platform.isAndroid) {
        // Android: use Downloads folder
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          // Fallback to app directory
          downloadDir = await getApplicationDocumentsDirectory();
        }
      } else {
        // Other platforms
        downloadDir = await getApplicationDocumentsDirectory();
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().toString().replaceAll(':', '-').split('.')[0];
      final fileName = 'expenses_$timestamp.csv';
      final filePath = '${downloadDir.path}/$fileName';
      
      // Write file
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString());
      
      print('CSV exported to: $filePath');
      return file;
      
    } catch (e) {
      print('Error exporting to CSV: $e');
      rethrow;
    }
  }

  /// Export expenses to JSON file
  Future<File?> exportToJSON() async {
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Get all expenses
      final dbService = DatabaseService();
      final expenses = await dbService.getAllExpenses();
      
      if (expenses.isEmpty) {
        throw Exception('No expenses to export');
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
          'note': e.note,
          'receiptPath': e.receiptPath,
        };
      }).toList();

      // Encode to JSON with pretty formatting
      String jsonString = JsonEncoder.withIndent('  ').convert(jsonList);

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

      // Create filename with timestamp
      final timestamp = DateTime.now().toString().replaceAll(':', '-').split('.')[0];
      final fileName = 'expenses_$timestamp.json';
      final filePath = '${downloadDir.path}/$fileName';
      
      // Write file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      print('JSON exported to: $filePath');
      return file;
      
    } catch (e) {
      print('Error exporting to JSON: $e');
      rethrow;
    }
  }

  /// Share the exported file
  Future<void> shareFile(File file) async {
    // You can integrate with share_plus package here
    print('File ready to share: ${file.path}');
  }

  /// Escape CSV fields (wrap in quotes if contains comma or quotes)
  String _escapeCSV(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Replace double quotes with two double quotes
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Format date for CSV
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}