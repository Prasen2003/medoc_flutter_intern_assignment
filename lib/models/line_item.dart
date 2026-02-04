import 'package:flutter/foundation.dart';

@immutable
class LineItem {
  const LineItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  final String id;
  final String label;
  final double amount;
  final DateTime date;
  final String notes;

  LineItem copyWith({
    String? id,
    String? label,
    double? amount,
    DateTime? date,
    String? notes,
  }) {
    return LineItem(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
