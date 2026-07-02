import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accounts_provider.dart';
import '../../domain/models/account_model.dart';
import 'dart:math';

class AddAccountSheet extends StatefulWidget {
  final AccountModel? account;
  const AddAccountSheet({super.key, this.account});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'Bank'; // Bank, Cash, Mobile

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.initialBalance.toString();
      _selectedType = widget.account!.type;
      if (!['Bank', 'Cash', 'Mobile', 'Saving'].contains(_selectedType)) {
         _selectedType = 'Bank';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (_nameController.text.trim().isEmpty) return;
    
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final provider = Provider.of<AccountsProvider>(context, listen: false);

    if (widget.account != null) {
      final account = widget.account!.copyWith(
        name: _nameController.text.trim(),
        type: _selectedType,
        initialBalance: balance,
      );
      provider.updateAccount(account);
    } else {
      final account = AccountModel(
        id: "acc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100)}",
        name: _nameController.text.trim(),
        type: _selectedType,
        initialBalance: balance,
        order: provider.accounts.length,
      );
      provider.addAccount(account);
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.account != null ? 'Edit Account' : 'Add New Account',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              hintText: 'e.g. Chase Bank, Main Wallet',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Initial Balance',
              hintText: '0.00',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),
          
          Text('Account Type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Bank', icon: Icon(Icons.account_balance_outlined), label: Text('Bank')),
              ButtonSegment(value: 'Cash', icon: Icon(Icons.money_outlined), label: Text('Cash')),
              ButtonSegment(value: 'Mobile', icon: Icon(Icons.phone_iphone_outlined), label: Text('Mobile')),
              ButtonSegment(value: 'Saving', icon: Icon(Icons.savings_outlined), label: Text('Saving')),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedType = newSelection.first;
              });
            },
          ),
          
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveAccount,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Save Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
