import 'package:flutter/foundation.dart';

import 'line_item.dart';

enum ClaimStatus {
  draft,
  submitted,
  approved,
  rejected,
  partiallySettled,
  fullySettled,
}

@immutable
class Claim {
  const Claim({
    required this.id,
    required this.patientName,
    required this.policyNumber,
    required this.hospitalName,
    required this.admissionDate,
    required this.dischargeDate,
    required this.status,
    required this.bills,
    required this.advances,
    required this.settlements,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientName;
  final String policyNumber;
  final String hospitalName;
  final DateTime admissionDate;
  final DateTime dischargeDate;
  final ClaimStatus status;
  final List<LineItem> bills;
  final List<LineItem> advances;
  final List<LineItem> settlements;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalBills => _sum(bills);
  double get totalAdvances => _sum(advances);
  double get totalSettlements => _sum(settlements);
  double get pendingAmount => totalBills - totalAdvances - totalSettlements;

  Claim copyWith({
    String? id,
    String? patientName,
    String? policyNumber,
    String? hospitalName,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    ClaimStatus? status,
    List<LineItem>? bills,
    List<LineItem>? advances,
    List<LineItem>? settlements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Claim(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      policyNumber: policyNumber ?? this.policyNumber,
      hospitalName: hospitalName ?? this.hospitalName,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      status: status ?? this.status,
      bills: bills ?? this.bills,
      advances: advances ?? this.advances,
      settlements: settlements ?? this.settlements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _sum(List<LineItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.amount);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'policyNumber': policyNumber,
      'hospitalName': hospitalName,
      'admissionDate': admissionDate.toIso8601String(),
      'dischargeDate': dischargeDate.toIso8601String(),
      'status': status.name,
      'bills': bills.map((item) => item.toJson()).toList(),
      'advances': advances.map((item) => item.toJson()).toList(),
      'settlements': settlements.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] as String,
      patientName: json['patientName'] as String,
      policyNumber: json['policyNumber'] as String,
      hospitalName: json['hospitalName'] as String,
      admissionDate: DateTime.parse(json['admissionDate'] as String),
      dischargeDate: DateTime.parse(json['dischargeDate'] as String),
      status: ClaimStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ClaimStatus.draft,
      ),
      bills: (json['bills'] as List<dynamic>)
          .map((item) => LineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      advances: (json['advances'] as List<dynamic>)
          .map((item) => LineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      settlements: (json['settlements'] as List<dynamic>)
          .map((item) => LineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

bool canTransition(ClaimStatus from, ClaimStatus to) {
  if (from == to) {
    return true;
  }
  switch (from) {
    case ClaimStatus.draft:
      return to == ClaimStatus.submitted;
    case ClaimStatus.submitted:
      return to == ClaimStatus.approved || to == ClaimStatus.rejected;
    case ClaimStatus.approved:
      return to == ClaimStatus.partiallySettled || to == ClaimStatus.fullySettled;
    case ClaimStatus.rejected:
      return false;
    case ClaimStatus.partiallySettled:
      return to == ClaimStatus.fullySettled;
    case ClaimStatus.fullySettled:
      return false;
  }
}

List<ClaimStatus> allowedTransitions(ClaimStatus status) {
  return ClaimStatus.values
      .where((candidate) => canTransition(status, candidate))
      .toList();
}
