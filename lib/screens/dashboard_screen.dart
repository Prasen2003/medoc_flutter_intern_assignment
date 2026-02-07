import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/claim_repository.dart';
import '../models/claim.dart';
import '../widgets/status_chip.dart';
import 'claim_editor_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final claims = context.watch<ClaimRepository>().claims;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Claim Dashboard'),
      ),
      body: claims.isEmpty
          ? _EmptyState(onCreate: () => _openCreate(context))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final claim = claims[index];
                return _ClaimCard(
                  claim: claim,
                  onOpen: () => _openEdit(context, claim.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ClaimEditorScreen()),
    );
  }

  void _openEdit(BuildContext context, String claimId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClaimEditorScreen(claimId: claimId)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No claims yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first claim to start tracking bills, advances, and settlements.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Claim'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.onOpen});

  final Claim claim;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.patientName,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  StatusChip(status: claim.status),
                ],
              ),
              const SizedBox(height: 4),
              Text('Policy: ${claim.policyNumber}'),
              Text('Hospital: ${claim.hospitalName}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _MetricTile(
                    label: 'Bills',
                    value: _formatMoney(claim.totalBills),
                  ),
                  _MetricTile(
                    label: 'Advances',
                    value: _formatMoney(claim.totalAdvances),
                  ),
                  _MetricTile(
                    label: 'Settled',
                    value: _formatMoney(claim.totalSettlements),
                  ),
                  if (claim.status == ClaimStatus.rejected)
                    _RejectedTile(
                      advances: _formatMoney(claim.totalAdvances),
                    )
                  else
                    _MetricTile(
                      label: 'Pending',
                      value: _formatMoney(claim.pendingAmount),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return 'INR ${value.toStringAsFixed(2)}';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _RejectedTile extends StatelessWidget {
  const _RejectedTile({required this.advances});

  final String advances;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Claim Rejected – No further settlement', style: textTheme.labelMedium),
          const SizedBox(height: 4),
          Text('Advance Paid: $advances', style: textTheme.titleSmall),
        ],
      ),
    );
  }
}
