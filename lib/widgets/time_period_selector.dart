import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TimePeriod { daily, weekly, monthly, yearly, custom }

class TimePeriodSelector extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod, DateTime?, DateTime?) onPeriodChanged;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const TimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  State<TimePeriodSelector> createState() => _TimePeriodSelectorState();
}

class _TimePeriodSelectorState extends State<TimePeriodSelector> {
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _customStartDate = widget.customStartDate;
    _customEndDate = widget.customEndDate;
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return 'Today';
      case TimePeriod.weekly:
        return 'This Week';
      case TimePeriod.monthly:
        return 'This Month';
      case TimePeriod.yearly:
        return 'This Year';
      case TimePeriod.custom:
        return 'Custom';
    }
  }

  Future<void> _selectCustomRange() async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (startDate != null) {
      final endDate = await showDatePicker(
        context: context,
        initialDate: _customEndDate ?? DateTime.now(),
        firstDate: startDate,
        lastDate: DateTime.now(),
      );
      
      if (endDate != null) {
        setState(() {
          _customStartDate = startDate;
          _customEndDate = endDate;
        });
        widget.onPeriodChanged(TimePeriod.custom, startDate, endDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TimePeriod.values.map((period) {
                final isSelected = widget.selectedPeriod == period;
                return FilterChip(
                  label: Text(_getPeriodLabel(period)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && period == TimePeriod.custom) {
                      _selectCustomRange();
                    } else if (selected) {
                      widget.onPeriodChanged(period, null, null);
                    }
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue,
                );
              }).toList(),
            ),
            if (widget.selectedPeriod == TimePeriod.custom && _customStartDate != null && _customEndDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}