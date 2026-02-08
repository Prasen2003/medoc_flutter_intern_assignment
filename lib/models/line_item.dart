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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] as String,
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: (json['notes'] as String?) ?? '',
    );
  }

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

enum LineItemType { bill, advance, settlement }
