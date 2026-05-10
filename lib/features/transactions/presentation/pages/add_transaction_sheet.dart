import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/transaction_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'package:uuid/uuid.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction;
  
  const AddTransactionSheet({super.key, this.transaction});

  static void show(BuildContext context, {TransactionModel? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: Theme.of(context).bottomSheetTheme.shape,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTransactionSheet(transaction: transaction),
      ),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  bool isExpense = true;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toString();
      _categoryController.text = tx.category;
      _noteController.text = tx.note;
      isExpense = tx.isExpense;
    }
  }

  void _saveTransaction() {
    final amountParsed = double.tryParse(_amountController.text) ?? 0.0;
    if (amountParsed <= 0 || _categoryController.text.isEmpty) {
      // Basic validation
      return;
    }

    final tx = TransactionModel(
      id: widget.transaction?.id ?? const Uuid().v4(),
      amount: amountParsed,
      category: _categoryController.text,
      note: _noteController.text,
      timestamp: widget.transaction?.timestamp ?? DateTime.now(),
      createdBy: widget.transaction?.createdBy ?? 'manual',
      accountId: widget.transaction?.accountId ?? 'default_account',
      isExpense: isExpense,
    );

    final provider = Provider.of<DashboardProvider>(context, listen: false);
    provider.addTransaction(tx);
    
    // Check if mounted before returning
    if (context.mounted) {
      Navigator.pop(context);
      final action = widget.transaction != null ? 'Updated' : 'Added';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action ৳${tx.amount.toStringAsFixed(0)} for ${tx.category}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.transaction != null ? 'Edit Transaction' : 'New Transaction', 
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                ),
                if (widget.transaction != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      final provider = Provider.of<DashboardProvider>(context, listen: false);
                      provider.deleteTransaction(widget.transaction!.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction deleted'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type toggle
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Expense'),
                    selected: isExpense,
                    onSelected: (val) => setState(() => isExpense = true),
                    selectedColor: Colors.redAccent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isExpense ? Colors.redAccent : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Income'),
                    selected: !isExpense,
                    onSelected: (val) => setState(() => isExpense = false),
                    selectedColor: Colors.green.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: !isExpense ? Colors.green : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '৳ ',
                labelText: 'Amount',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category (e.g. Food, Transport)',
                filled: true,
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                filled: true,
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                widget.transaction != null ? 'Update Transaction' : 'Save Transaction', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
