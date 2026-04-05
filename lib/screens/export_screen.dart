import 'package:flutter/material.dart';
import 'dart:io';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  String? _exportedFilePath;
  File? _exportedFile;

  Future<void> _exportCSV() async {
    setState(() {
      _isExporting = true;
      _exportedFilePath = null;
    });

    try {
      final file = await ExportService().exportToCSV();
      
      if (file != null && mounted) {
        setState(() {
          _exportedFile = file;
          _exportedFilePath = file.path;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported to: ${file.path.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportJSON() async {
    setState(() {
      _isExporting = true;
      _exportedFilePath = null;
    });

    try {
      final file = await ExportService().exportToJSON();
      
      if (file != null && mounted) {
        setState(() {
          _exportedFile = file;
          _exportedFilePath = file.path;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('JSON exported to: ${file.path.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _openFileLocation() async {
    if (_exportedFilePath == null) return;
    
    try {
      final file = File(_exportedFilePath!);
      if (await file.exists()) {
        // On Linux, open the containing folder
        if (Platform.isLinux) {
          final directory = file.parent;
          await Process.run('xdg-open', [directory.path]);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open folder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Export your expense data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose CSV for spreadsheets (Excel/Sheets) or JSON for developers',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // CSV Export Button
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportCSV,
              icon: const Icon(Icons.table_chart),
              label: Text(_isExporting ? 'Exporting...' : 'Export as CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // JSON Export Button
            OutlinedButton.icon(
              onPressed: _isExporting ? null : _exportJSON,
              icon: const Icon(Icons.code),
              label: Text(_isExporting ? 'Exporting...' : 'Export as JSON'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                side: const BorderSide(color: Colors.blue),
              ),
            ),
            
            if (_isExporting) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Generating export...'),
                  ],
                ),
              ),
            ],
            
            if (_exportedFilePath != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Export Successful!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'File saved to:',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _exportedFilePath!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _openFileLocation,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Open Folder'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}