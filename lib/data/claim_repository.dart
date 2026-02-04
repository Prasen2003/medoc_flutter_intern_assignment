import 'package:flutter/foundation.dart';

import '../models/claim.dart';
import '../models/line_item.dart';

class ClaimRepository extends ChangeNotifier {
  final List<Claim> _claims = [];

  List<Claim> get claims => List.unmodifiable(_claims);

  void addClaim(Claim claim) {
    _claims.insert(0, claim);
    notifyListeners();
  }

  void updateClaim(Claim updated) {
    final index = _claims.indexWhere((claim) => claim.id == updated.id);
    if (index == -1) {
      return;
    }
    _claims[index] = updated;
    notifyListeners();
  }

  void deleteClaim(String id) {
    _claims.removeWhere((claim) => claim.id == id);
    notifyListeners();
  }

  Claim? findById(String id) {
    final match = _claims.where((claim) => claim.id == id);
    if (match.isEmpty) {
      return null;
    }
    return match.first;
  }

  void addLineItem({
    required String claimId,
    required LineItem item,
    required LineItemType type,
  }) {
    final claim = findById(claimId);
    if (claim == null) {
      return;
    }
    updateClaim(_withItemAdded(claim, type, item));
  }

  void updateLineItem({
    required String claimId,
    required LineItem item,
    required LineItemType type,
  }) {
    final claim = findById(claimId);
    if (claim == null) {
      return;
    }
    updateClaim(_withItemUpdated(claim, type, item));
  }

  void removeLineItem({
    required String claimId,
    required String itemId,
    required LineItemType type,
  }) {
    final claim = findById(claimId);
    if (claim == null) {
      return;
    }
    updateClaim(_withItemRemoved(claim, type, itemId));
  }

  Claim _withItemAdded(Claim claim, LineItemType type, LineItem item) {
    return claim.copyWith(
      updatedAt: DateTime.now(),
      bills: type == LineItemType.bill
          ? [...claim.bills, item]
          : claim.bills,
      advances: type == LineItemType.advance
          ? [...claim.advances, item]
          : claim.advances,
      settlements: type == LineItemType.settlement
          ? [...claim.settlements, item]
          : claim.settlements,
    );
  }

  Claim _withItemUpdated(Claim claim, LineItemType type, LineItem item) {
    List<LineItem> updateList(List<LineItem> items) {
      return items.map((existing) {
        return existing.id == item.id ? item : existing;
      }).toList();
    }

    return claim.copyWith(
      updatedAt: DateTime.now(),
      bills: type == LineItemType.bill ? updateList(claim.bills) : claim.bills,
      advances: type == LineItemType.advance
          ? updateList(claim.advances)
          : claim.advances,
      settlements: type == LineItemType.settlement
          ? updateList(claim.settlements)
          : claim.settlements,
    );
  }

  Claim _withItemRemoved(Claim claim, LineItemType type, String itemId) {
    List<LineItem> removeList(List<LineItem> items) {
      return items.where((item) => item.id != itemId).toList();
    }

    return claim.copyWith(
      updatedAt: DateTime.now(),
      bills: type == LineItemType.bill ? removeList(claim.bills) : claim.bills,
      advances: type == LineItemType.advance
          ? removeList(claim.advances)
          : claim.advances,
      settlements: type == LineItemType.settlement
          ? removeList(claim.settlements)
          : claim.settlements,
    );
  }
}

enum LineItemType { bill, advance, settlement }
