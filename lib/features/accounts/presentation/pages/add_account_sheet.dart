import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accounts_provider.dart';
import '../../domain/models/account_model.dart';
import 'dart:math';

class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'Bank'; // Bank, Cash, Mobile

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (_nameController.text.trim().isEmpty) return;
    
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final account = AccountModel(
      id: "acc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100)}",
      name: _nameController.text.trim(),
      type: _selectedType,
      initialBalance: balance,
    );

    Provider.of<AccountsProvider>(context, listen: false).addAccount(account);
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
            'Add New Account',
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
