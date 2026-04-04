import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class ExportConfigScreen extends StatefulWidget {
  const ExportConfigScreen({super.key});

  @override
  State<ExportConfigScreen> createState() => _ExportConfigScreenState();
}

class _ExportConfigScreenState extends State<ExportConfigScreen> {
  // Date range selection
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useDateRange = false;
  
  // Export format
  String _selectedFormat = 'CSV';
  
  // Export status
  bool _isExporting = false;
  String? _exportedFilePath;
  
  // Date range presets
  final Map<String, Map<String, dynamic>> _presets = {
    'Current Month': {
      'start': DateTime(DateTime.now().year, DateTime.now().month, 1),
      'end': DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
    },
    'Last Month': {
      'start': DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
      'end': DateTime(DateTime.now().year, DateTime.now().month, 0),
    },
    'Current Year': {
      'start': DateTime(DateTime.now().year, 1, 1),
      'end': DateTime(DateTime.now().year, 12, 31),
    },
    'Last 30 Days': {
      'start': DateTime.now().subtract(const Duration(days: 30)),
      'end': DateTime.now(),
    },
    'Last 90 Days': {
      'start': DateTime.now().subtract(const Duration(days: 90)),
      'end': DateTime.now(),
    },
  };

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _exportedFilePath = null;
    });

    try {
      File? file;
      
      if (_selectedFormat == 'CSV') {
        file = await ExportService().exportToCSV(
          startDate: _useDateRange ? _startDate : null,
          endDate: _useDateRange ? _endDate : null,
        );
      } else {
        file = await ExportService().exportToJSON(
          startDate: _useDateRange ? _startDate : null,
          endDate: _useDateRange ? _endDate : null,
        );
      }
      
      // Fix: Proper null check with file path assignment
      if (file != null) {
        final filePath = file.path;
        if (mounted) {
          setState(() {
            _exportedFilePath = filePath;
          });
        }
        
        // Get summary
        final summary = await ExportService().getExportSummary(
          startDate: _useDateRange ? _startDate : null,
          endDate: _useDateRange ? _endDate : null,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Exported ${summary['count']} expenses totaling \$${summary['total'].toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Failed to create export file');
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

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _applyPreset(String presetName) {
    final preset = _presets[presetName];
    if (preset != null && mounted) {
      setState(() {
        _startDate = preset['start'];
        _endDate = preset['end'];
        _useDateRange = true;
      });
    }
  }

  Future<void> _openFileLocation() async {
    if (_exportedFilePath == null) return;
    
    try {
      final file = File(_exportedFilePath!);
      if (await file.exists()) {
        if (Platform.isLinux) {
          final directory = file.parent;
          await Process.run('xdg-open', [directory.path]);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open folder: $e')),
        );
      }
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
      body: SingleChildScrollView(
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
                      'Configure your export',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select date range and format to export your expenses',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Export Format Selection
            const Text(
              'Export Format',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'CSV', label: Text('CSV (Excel)')),
                ButtonSegment(value: 'JSON', label: Text('JSON')),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedFormat = selection.first;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Date Range Toggle
            SwitchListTile(
              title: const Text('Filter by Date Range'),
              subtitle: const Text('Export only expenses within a specific date range'),
              value: _useDateRange,
              onChanged: (value) {
                setState(() {
                  _useDateRange = value;
                  if (!value) {
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
              activeColor: Colors.green,
            ),
            
            if (_useDateRange) ...[
              const SizedBox(height: 16),
              
              // Quick Presets
              const Text(
                'Quick Presets',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.keys.map((preset) {
                  return ActionChip(
                    label: Text(preset),
                    onPressed: () => _applyPreset(preset),
                    backgroundColor: Colors.green.shade50,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Custom Date Range
              const Text(
                'Custom Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('Start Date', style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                _startDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                    : 'Select',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('End Date', style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                _endDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                    : 'Select',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Export Button
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportData,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
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
                          _exportedFilePath!.split('/').last,
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