import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/claim.dart';
import '../models/line_item.dart';

class ClaimRepository extends ChangeNotifier {
  ClaimRepository() {
    _load();
  }

  static const _storageKey = 'claims_storage_v1';
  final List<Claim> _claims = [];
  bool _loaded = false;

  List<Claim> get claims => List.unmodifiable(_claims);
  bool get isLoaded => _loaded;

  void addClaim(Claim claim) {
    _claims.insert(0, claim);
    _persist();
    notifyListeners();
  }

  void updateClaim(Claim updated) {
    final index = _claims.indexWhere((claim) => claim.id == updated.id);
    if (index == -1) {
      return;
    }
    _claims[index] = updated;
    _persist();
    notifyListeners();
  }

  void deleteClaim(String id) {
    _claims.removeWhere((claim) => claim.id == id);
    _persist();
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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _claims
        ..clear()
        ..addAll(
          decoded.map((item) => Claim.fromJson(item as Map<String, dynamic>)),
        );
    } catch (_) {
      _claims.clear();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_claims.map((claim) => claim.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
