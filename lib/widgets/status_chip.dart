import 'package:flutter/material.dart';

import '../models/claim.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      ClaimStatus.draft => scheme.outline,
      ClaimStatus.submitted => scheme.primary,
      ClaimStatus.approved => Colors.green.shade600,
      ClaimStatus.rejected => scheme.error,
      ClaimStatus.partiallySettled => Colors.orange.shade700,
    };

    return Chip(
      label: Text(_label(status)),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.5))),
    );
  }

  String _label(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.partiallySettled:
        return 'Partially Settled';
    }
  }
}
