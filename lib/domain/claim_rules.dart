import '../models/claim.dart';
import '../models/line_item.dart';

class ClaimRules {
  static bool canDelete(ClaimStatus status) {
    return status == ClaimStatus.draft || status == ClaimStatus.submitted;
  }

  static bool isDraftEditable(ClaimStatus status) {
    return status == ClaimStatus.draft || status == ClaimStatus.submitted;
  }

  static bool canModifyAdvances(ClaimStatus status) {
    return status == ClaimStatus.submitted ||
        status == ClaimStatus.approved ||
        status == ClaimStatus.partiallySettled;
  }

  static bool canModifySettlements(ClaimStatus status) {
    return status == ClaimStatus.approved ||
        status == ClaimStatus.partiallySettled;
  }

  static bool canAddLineItem(LineItemType type, ClaimStatus status) {
    if (type == LineItemType.bill) {
      return isDraftEditable(status);
    }
    if (type == LineItemType.advance) {
      return canModifyAdvances(status);
    }
    return canModifySettlements(status);
  }

  static bool totalsValid({
    required double bills,
    required double advances,
    required double settlements,
  }) {
    return (advances + settlements) <= bills;
  }

  static bool hasBillsForStatus(ClaimStatus status, int billCount) {
    if (status == ClaimStatus.draft || status == ClaimStatus.submitted) {
      return billCount > 0;
    }
    return true;
  }

  static StatusResolution resolveStatusAfterSettlements(
    ClaimStatus status,
    Totals totals,
  ) {
    final affectsSettlementStatus = status == ClaimStatus.approved ||
        status == ClaimStatus.partiallySettled ||
        status == ClaimStatus.fullySettled;

    if (totals.pendingAmount == 0 && affectsSettlementStatus) {
      return const StatusResolution(
        ClaimStatus.fullySettled,
        'Status set to Fully Settled.',
      );
    }

    if (totals.totalSettlements > 0 &&
        totals.pendingAmount > 0 &&
        affectsSettlementStatus) {
      return const StatusResolution(
        ClaimStatus.partiallySettled,
        'Status set to Partially Settled.',
      );
    }

    if (totals.totalSettlements == 0 &&
        (status == ClaimStatus.partiallySettled ||
            status == ClaimStatus.fullySettled)) {
      return const StatusResolution(
        ClaimStatus.approved,
        'Status reverted to Approved.',
      );
    }

    return StatusResolution(status, null);
  }
}

class Totals {
  const Totals({
    required this.totalBills,
    required this.totalAdvances,
    required this.totalSettlements,
  });

  final double totalBills;
  final double totalAdvances;
  final double totalSettlements;

  double get pendingAmount => totalBills - totalAdvances - totalSettlements;
}

class StatusResolution {
  const StatusResolution(this.status, this.message);

  final ClaimStatus status;
  final String? message;
}
