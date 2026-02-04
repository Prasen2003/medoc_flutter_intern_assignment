import 'package:flutter/foundation.dart';

import 'line_item.dart';

enum ClaimStatus {
  draft,
  submitted,
  approved,
  rejected,
  partiallySettled,
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
      return to == ClaimStatus.partiallySettled;
    case ClaimStatus.rejected:
      return false;
    case ClaimStatus.partiallySettled:
      return false;
  }
}

List<ClaimStatus> allowedTransitions(ClaimStatus status) {
  return ClaimStatus.values
      .where((candidate) => canTransition(status, candidate))
      .toList();
}
