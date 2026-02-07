import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/claim_repository.dart';
import '../models/claim.dart';
import '../models/line_item.dart';
import '../widgets/status_chip.dart';

class ClaimEditorScreen extends StatefulWidget {
  const ClaimEditorScreen({super.key, this.claimId});

  final String? claimId;

  @override
  State<ClaimEditorScreen> createState() => _ClaimEditorScreenState();
}

class _ClaimEditorScreenState extends State<ClaimEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _patientController = TextEditingController();
  final _policyController = TextEditingController();
  final _hospitalController = TextEditingController();

  DateTime _admissionDate = DateTime.now();
  DateTime _dischargeDate = DateTime.now();
  ClaimStatus _status = ClaimStatus.draft;
  ClaimStatus _originalStatus = ClaimStatus.draft;

  List<LineItem> _bills = [];
  List<LineItem> _advances = [];
  List<LineItem> _settlements = [];

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    final claimId = widget.claimId;
    if (claimId == null) {
      return;
    }
    final repo = context.read<ClaimRepository>();
    final claim = repo.findById(claimId);
    if (claim == null) {
      return;
    }
    _patientController.text = claim.patientName;
    _policyController.text = claim.policyNumber;
    _hospitalController.text = claim.hospitalName;
    _admissionDate = claim.admissionDate;
    _dischargeDate = claim.dischargeDate;
    _status = claim.status;
    _originalStatus = claim.status;
    _bills = List.of(claim.bills);
    _advances = List.of(claim.advances);
    _settlements = List.of(claim.settlements);
  }

  @override
  void dispose() {
    _patientController.dispose();
    _policyController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.claimId != null;
    final totals = _Totals.fromItems(_bills, _advances, _settlements);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Claim' : 'Create Claim'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Delete claim',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Patient Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _patientController,
              enabled: _isDraftEditable(),
              decoration: const InputDecoration(
                labelText: 'Patient name',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _policyController,
              enabled: _isDraftEditable(),
              decoration: const InputDecoration(
                labelText: 'Policy number',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hospitalController,
              enabled: _isDraftEditable(),
              decoration: const InputDecoration(
                labelText: 'Hospital name',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),
            _DateRow(
              admissionDate: _admissionDate,
              dischargeDate: _dischargeDate,
              onPickAdmission:
                  _isDraftEditable() ? () => _pickDate(context, true) : null,
              onPickDischarge:
                  _isDraftEditable() ? () => _pickDate(context, false) : null,
            ),
            const SizedBox(height: 16),
            _StatusRow(
              status: _status,
              options: _statusOptions(),
              onChanged: _handleStatusChange,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Bills',
              subtitle: 'Medical expenses claimed by the hospital',
              onAdd: _isDraftEditable()
                  ? () => _addLineItem(context, LineItemType.bill)
                  : null,
            ),
            _LineItemList(
              items: _bills,
              type: LineItemType.bill,
              canEdit: _isDraftEditable(),
              onEdit: _editLineItem,
              onRemove: _removeLineItem,
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Advances',
              subtitle: 'Advance payments given by the insurer',
              onAdd: _canModifyAdvances()
                  ? () => _addLineItem(context, LineItemType.advance)
                  : null,
            ),
            _LineItemList(
              items: _advances,
              type: LineItemType.advance,
              canEdit: _canModifyAdvances(),
              onEdit: _editLineItem,
              onRemove: _removeLineItem,
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Settlements',
              subtitle: 'Final settlement payments issued',
              onAdd: _canModifySettlements()
                  ? () => _addLineItem(context, LineItemType.settlement)
                  : null,
            ),
            _LineItemList(
              items: _settlements,
              type: LineItemType.settlement,
              canEdit: _canModifySettlements(),
              onEdit: _editLineItem,
              onRemove: _removeLineItem,
            ),
            const SizedBox(height: 20),
            _TotalsCard(totals: totals),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _saveClaim(context),
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Save Changes' : 'Create Claim'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required field';
    }
    return null;
  }

  Future<void> _pickDate(BuildContext context, bool isAdmission) async {
    final initial = isAdmission ? _admissionDate : _dischargeDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    // ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    if (isAdmission && picked.isAfter(_dischargeDate)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Admission date cannot be after discharge date.'),
        ),
      );
      return;
    }
    if (!isAdmission && picked.isBefore(_admissionDate)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Discharge date cannot be before admission date.'),
        ),
      );
      return;
    }
    setState(() {
      if (isAdmission) {
        _admissionDate = picked;
      } else {
        _dischargeDate = picked;
      }
    });
  }

  Future<void> _addLineItem(BuildContext context, LineItemType type) async {
    if (!_canAddLineItem(type)) {
      _showNotAllowedMessage(type);
      return;
    }
    final item = await _showLineItemDialog(context, type);
    if (item == null) {
      return;
    }
    if (!_canApplyLineItem(type, item)) {
      _showExceedsBillsMessage();
      return;
    }
    setState(() {
      _listForType(type).add(item);
    });
  }

  Future<void> _editLineItem(LineItemType type, LineItem item) async {
    final updated = await _showLineItemDialog(context, type, existing: item);
    if (updated == null) {
      return;
    }
    if (!_canApplyLineItem(type, updated, editingId: item.id)) {
      _showExceedsBillsMessage();
      return;
    }
    setState(() {
      final list = _listForType(type);
      final index = list.indexWhere((element) => element.id == item.id);
      if (index != -1) {
        list[index] = updated;
      }
    });
  }

  void _removeLineItem(LineItemType type, LineItem item) {
    setState(() {
      _listForType(type).removeWhere((element) => element.id == item.id);
    });
  }

  List<LineItem> _listForType(LineItemType type) {
    switch (type) {
      case LineItemType.bill:
        return _bills;
      case LineItemType.advance:
        return _advances;
      case LineItemType.settlement:
        return _settlements;
    }
  }

  Future<LineItem?> _showLineItemDialog(
    BuildContext context,
    LineItemType type, {
    LineItem? existing,
  }) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    DateTime selectedDate = existing?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    return showDialog<LineItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${existing == null ? 'Add' : 'Edit'} ${_typeLabel(type)}'),
              content: SizedBox(
                width: 360,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label',
                          border: OutlineInputBorder(),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: 'INR ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required field';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${_formatDate(selectedDate)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            child: const Text('Pick'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    final amount = double.parse(amountController.text.trim());
                    final item = LineItem(
                      id: existing?.id ?? _newId(),
                      label: labelController.text.trim(),
                      amount: amount,
                      date: selectedDate,
                      notes: notesController.text.trim(),
                    );
                    Navigator.of(context).pop(item);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveClaim(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_patientController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient name is required.')),
      );
      return;
    }

    if ((_originalStatus == ClaimStatus.draft ||
            _originalStatus == ClaimStatus.submitted) &&
        _bills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one bill before saving.')),
      );
      return;
    }

    if (!_areTotalsValid()) {
      _showExceedsBillsMessage();
      return;
    }

    if (_dischargeDate.isBefore(_admissionDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discharge date must be after admission.')),
      );
      return;
    }

    var status = _status;
    if (!canTransition(_originalStatus, status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid status transition. Please save in order.'),
        ),
      );
      return;
    }

    if (_requiresSaveConfirmation(status)) {
      final confirmed = await _confirmStatusChange(status);
      if (!mounted || confirmed != true) {
        return;
      }
    }
    final totals = _Totals.fromItems(_bills, _advances, _settlements);
    if (totals.pendingAmount == 0 &&
        (status == ClaimStatus.approved ||
            status == ClaimStatus.partiallySettled ||
            status == ClaimStatus.fullySettled)) {
      status = ClaimStatus.fullySettled;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status set to Fully Settled.')),
      );
    } else if (totals.totalSettlements > 0 &&
        totals.pendingAmount > 0 &&
        (status == ClaimStatus.approved ||
            status == ClaimStatus.partiallySettled ||
            status == ClaimStatus.fullySettled)) {
      status = ClaimStatus.partiallySettled;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status set to Partially Settled.')),
      );
    } else if (totals.totalSettlements == 0 &&
        (status == ClaimStatus.partiallySettled ||
            status == ClaimStatus.fullySettled)) {
      status = ClaimStatus.approved;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status reverted to Approved.')),
      );
    }

    // ignore: use_build_context_synchronously
    final repo = context.read<ClaimRepository>();
    final now = DateTime.now();
    final claim = Claim(
      id: widget.claimId ?? _newId(),
      patientName: _patientController.text.trim(),
      policyNumber: _policyController.text.trim(),
      hospitalName: _hospitalController.text.trim(),
      admissionDate: _admissionDate,
      dischargeDate: _dischargeDate,
      status: status,
      bills: List.of(_bills),
      advances: List.of(_advances),
      settlements: List.of(_settlements),
      createdAt: widget.claimId == null ? now : repo.findById(widget.claimId!)?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.claimId == null) {
      repo.addClaim(claim);
    } else {
      repo.updateClaim(claim);
    }

    if (!mounted) {
      return;
    }
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete claim?'),
          content: const Text('This will remove the claim permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result != true) {
      return;
    }

    if (widget.claimId != null) {
      context.read<ClaimRepository>().deleteClaim(widget.claimId!);
    }

    Navigator.of(context).pop();
  }

  String _typeLabel(LineItemType type) {
    switch (type) {
      case LineItemType.bill:
        return 'Bill';
      case LineItemType.advance:
        return 'Advance';
      case LineItemType.settlement:
        return 'Settlement';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  bool _isDraftEditable() {
    return _status == ClaimStatus.draft || _status == ClaimStatus.submitted;
  }

  bool _canModifyAdvances() {
    return _status == ClaimStatus.submitted ||
        _status == ClaimStatus.approved ||
        _status == ClaimStatus.partiallySettled ||
        _status == ClaimStatus.fullySettled;
  }

  bool _canModifySettlements() {
    return _status == ClaimStatus.approved ||
        _status == ClaimStatus.partiallySettled ||
        _status == ClaimStatus.fullySettled;
  }

  bool _canAddLineItem(LineItemType type) {
    if (type == LineItemType.bill) {
      return _isDraftEditable();
    }
    if (type == LineItemType.advance) {
      return _canModifyAdvances();
    }
    return _canModifySettlements();
  }

  bool _canApplyLineItem(
    LineItemType type,
    LineItem item, {
    String? editingId,
  }) {
    if (type == LineItemType.bill) {
      return true;
    }
    final billsTotal = _sumAmounts(_bills);
    double advancesTotal = _sumAmounts(_advances);
    double settlementsTotal = _sumAmounts(_settlements);

    if (type == LineItemType.advance) {
      advancesTotal = _recalculateTotal(_advances, item, editingId);
    } else {
      settlementsTotal = _recalculateTotal(_settlements, item, editingId);
    }

    return (advancesTotal + settlementsTotal) <= billsTotal;
  }

  bool _areTotalsValid() {
    final billsTotal = _sumAmounts(_bills);
    final advancesTotal = _sumAmounts(_advances);
    final settlementsTotal = _sumAmounts(_settlements);
    return (advancesTotal + settlementsTotal) <= billsTotal;
  }

  double _sumAmounts(List<LineItem> items) {
    return items.fold<double>(0, (total, item) => total + item.amount);
  }

  double _recalculateTotal(
    List<LineItem> items,
    LineItem updated,
    String? editingId,
  ) {
    return items.fold<double>(0, (total, item) {
      if (editingId != null && item.id == editingId) {
        return total + updated.amount;
      }
      return total + item.amount;
    });
  }

  void _showNotAllowedMessage(LineItemType type) {
    final label = _typeLabel(type).toLowerCase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == LineItemType.settlement
              ? 'Settlements are available after approval.'
              : 'Cannot add $label in draft status.',
        ),
      ),
    );
  }

  void _showExceedsBillsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Advances + settlements cannot exceed total bills.'),
      ),
    );
  }

  List<ClaimStatus> _statusOptions() {
    switch (_originalStatus) {
      case ClaimStatus.draft:
        return const [ClaimStatus.draft, ClaimStatus.submitted];
      case ClaimStatus.submitted:
        return const [
          ClaimStatus.submitted,
          ClaimStatus.approved,
          ClaimStatus.rejected,
        ];
      case ClaimStatus.approved:
        return const [ClaimStatus.approved];
      case ClaimStatus.rejected:
        return const [ClaimStatus.rejected];
      case ClaimStatus.partiallySettled:
        return const [ClaimStatus.partiallySettled];
      case ClaimStatus.fullySettled:
        return const [ClaimStatus.fullySettled];
    }
  }

  Future<void> _handleStatusChange(ClaimStatus nextStatus) async {
    if (nextStatus == _status) {
      return;
    }
    setState(() {
      _status = nextStatus;
      if (nextStatus == ClaimStatus.draft) {
        _advances = [];
        _settlements = [];
      } else if (nextStatus == ClaimStatus.submitted ||
          nextStatus == ClaimStatus.rejected) {
        _settlements = [];
      }
    });
  }

  bool _requiresSaveConfirmation(ClaimStatus status) {
    if (status == _originalStatus) {
      return false;
    }
    return status == ClaimStatus.submitted ||
        status == ClaimStatus.approved ||
        status == ClaimStatus.rejected;
  }

  Future<bool?> _confirmStatusChange(ClaimStatus status) {
    final message = switch (status) {
      ClaimStatus.submitted => 'Are you sure you want to submit this claim?',
      ClaimStatus.approved => 'Are you sure you want to approve this claim?',
      ClaimStatus.rejected => 'Are you sure you want to reject this claim?',
      _ => null,
    };
    if (message == null) {
      return Future.value(true);
    }
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm status change'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.admissionDate,
    required this.dischargeDate,
    required this.onPickAdmission,
    required this.onPickDischarge,
  });

  final DateTime admissionDate;
  final DateTime dischargeDate;
  final VoidCallback? onPickAdmission;
  final VoidCallback? onPickDischarge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickAdmission,
            icon: const Icon(Icons.calendar_month),
            label: Text('Admission: ${_formatDate(admissionDate)}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickDischarge,
            icon: const Icon(Icons.event_available),
            label: Text('Discharge: ${_formatDate(dischargeDate)}'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.options,
    required this.onChanged,
  });

  final ClaimStatus status;
  final List<ClaimStatus> options;
  final ValueChanged<ClaimStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Status:'),
        const SizedBox(width: 12),
        StatusChip(status: status),
        const Spacer(),
        DropdownButton<ClaimStatus>(
          value: status,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(_label(option)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
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
      case ClaimStatus.fullySettled:
        return 'Fully Settled';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

class _LineItemList extends StatelessWidget {
  const _LineItemList({
    required this.items,
    required this.type,
    required this.canEdit,
    required this.onEdit,
    required this.onRemove,
  });

  final List<LineItem> items;
  final LineItemType type;
  final bool canEdit;
  final void Function(LineItemType, LineItem) onEdit;
  final void Function(LineItemType, LineItem) onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          'No ${_label(type).toLowerCase()} added yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      children: items.map((item) {
        return Card(
          child: ListTile(
            title: Text(item.label),
            subtitle: Text(
              'INR ${item.amount.toStringAsFixed(2)} • ${_formatDate(item.date)}',
            ),
            trailing: canEdit
                ? Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(type, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onRemove(type, item),
                      ),
                    ],
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  String _label(LineItemType type) {
    switch (type) {
      case LineItemType.bill:
        return 'Bill';
      case LineItemType.advance:
        return 'Advance';
      case LineItemType.settlement:
        return 'Settlement';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final _Totals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TotalRow(label: 'Total Bills', value: totals.totalBills),
            _TotalRow(label: 'Total Advances', value: totals.totalAdvances),
            _TotalRow(label: 'Total Settlements', value: totals.totalSettlements),
            const Divider(),
            _TotalRow(label: 'Pending Amount', value: totals.pendingAmount),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('INR ${value.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

class _Totals {
  const _Totals({
    required this.totalBills,
    required this.totalAdvances,
    required this.totalSettlements,
    required this.pendingAmount,
  });

  final double totalBills;
  final double totalAdvances;
  final double totalSettlements;
  final double pendingAmount;

  factory _Totals.fromItems(
    List<LineItem> bills,
    List<LineItem> advances,
    List<LineItem> settlements,
  ) {
    double sum(List<LineItem> items) {
      return items.fold<double>(0, (total, item) => total + item.amount);
    }

    final totalBills = sum(bills);
    final totalAdvances = sum(advances);
    final totalSettlements = sum(settlements);
    return _Totals(
      totalBills: totalBills,
      totalAdvances: totalAdvances,
      totalSettlements: totalSettlements,
      pendingAmount: totalBills - totalAdvances - totalSettlements,
    );
  }
}
