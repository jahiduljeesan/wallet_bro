import 'package:flutter/material.dart';
import '../providers/debt_provider.dart';

import '../../domain/models/debt_model.dart';
import '../../../../core/services/hive_service.dart';

class AddDebtSheet extends StatefulWidget {
  final DebtProvider provider;
  final DebtModel? debt;

  const AddDebtSheet({super.key, required this.provider, this.debt});

  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  String _personName = '';
  double _amount = 0.0;
  String _note = '';
  bool _isDebt = true; // Default to "I Owe"
  String _selectedAccountId = 'cash_account';

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _personName = widget.debt!.personName;
      _amount = widget.debt!.amount;
      _note = widget.debt!.note;
      _isDebt = widget.debt!.isDebt;
      _selectedAccountId = widget.debt!.accountId;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await widget.provider.addDebt(
        id: widget.debt?.id,
        personName: _personName,
        amount: _amount,
        isDebt: _isDebt,
        note: _note,
        accountId: _selectedAccountId,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = HiveService.accountsBox.values.toList();
    if (accounts.isEmpty && _selectedAccountId != 'cash_account') {
        _selectedAccountId = 'cash_account';
    } else if (accounts.isNotEmpty && !accounts.any((a) => a.id == _selectedAccountId)) {
        _selectedAccountId = accounts.first.id;
    }

    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.debt != null ? 'Edit Record' : 'Add Record',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('I Owe (Debt)'),
                      selected: _isDebt,
                      onSelected: (val) {
                        setState(() => _isDebt = true);
                      },
                      selectedColor: Colors.redAccent.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Owed to Me (Lend)'),
                      selected: !_isDebt,
                      onSelected: (val) {
                        setState(() => _isDebt = false);
                      },
                      selectedColor: Colors.greenAccent.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _personName,
                decoration: const InputDecoration(
                  labelText: 'Person Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _personName = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.debt != null ? _amount.toString() : null,
                decoration: const InputDecoration(
                  labelText: 'Amount (৳)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _note,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                onSaved: (val) => _note = val ?? '',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: [
                  if (accounts.isEmpty)
                    const DropdownMenuItem(
                      value: 'cash_account',
                      child: Text('Cash'),
                    )
                  else
                    ...accounts.map((acc) => DropdownMenuItem(
                          value: acc.id,
                          child: Text(acc.name),
                        )),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAccountId = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Record', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
