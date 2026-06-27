import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/transaction_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/widgets/category_icon.dart';
import '../../../categories/presentation/pages/category_management_page.dart';

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
  bool isTransfer = false;
  String? _selectedAccountId;
  String? _targetAccountId;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
    final accounts = accountsProvider.accounts;

    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toString();
      _categoryController.text = tx.category;
      _noteController.text = tx.note;
      isExpense = tx.isExpense;
      _selectedDateTime = tx.timestamp;
      _selectedAccountId = tx.accountId;
      if (!accounts.any((acc) => acc.id == _selectedAccountId)) {
        _selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
      }
      isTransfer = tx.category == 'Transfer';
    } else {
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
        if (accounts.length > 1) {
          _targetAccountId = accounts[1].id;
        }
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _saveTransaction() {
    final amountParsed = double.tryParse(_amountController.text) ?? 0.0;
    if (amountParsed <= 0) {
      return;
    }
    if (!isTransfer && _categoryController.text.trim().isEmpty) {
      return;
    }

    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
    if (accountsProvider.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = Provider.of<DashboardProvider>(context, listen: false);

    if (isTransfer) {
      if (_selectedAccountId == null || _targetAccountId == null || _selectedAccountId == _targetAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select different From and To accounts'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final fromAccName = accountsProvider.accounts.firstWhere((a) => a.id == _selectedAccountId).name;
      final toAccName = accountsProvider.accounts.firstWhere((a) => a.id == _targetAccountId).name;

      final expenseTx = TransactionModel(
        id: const Uuid().v4(),
        amount: amountParsed,
        category: 'Transfer',
        note: _noteController.text.isEmpty 
            ? 'Transfer to $toAccName' 
            : '${_noteController.text} (Transfer to $toAccName)',
        timestamp: _selectedDateTime,
        createdBy: 'manual',
        accountId: _selectedAccountId!,
        isExpense: true,
      );

      final incomeTx = TransactionModel(
        id: const Uuid().v4(),
        amount: amountParsed,
        category: 'Transfer',
        note: _noteController.text.isEmpty 
            ? 'Transfer from $fromAccName' 
            : '${_noteController.text} (Transfer from $fromAccName)',
        timestamp: _selectedDateTime,
        createdBy: 'manual',
        accountId: _targetAccountId!,
        isExpense: false,
      );

      provider.addTransaction(expenseTx);
      provider.addTransaction(incomeTx);
    } else {
      final tx = TransactionModel(
        id: widget.transaction?.id ?? const Uuid().v4(),
        amount: amountParsed,
        category: _categoryController.text.trim(),
        note: _noteController.text.trim(),
        timestamp: _selectedDateTime,
        createdBy: widget.transaction?.createdBy ?? 'manual',
        accountId: _selectedAccountId ?? 'default_account',
        isExpense: isExpense,
      );
      provider.addTransaction(tx);
    }
    
    if (context.mounted) {
      Navigator.pop(context);
      final action = widget.transaction != null ? 'Updated' : 'Added';
      final msg = isTransfer ? 'Transfer completed' : '$action ৳${amountParsed.toStringAsFixed(0)} for ${_categoryController.text}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
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
    final accountsProvider = Provider.of<AccountsProvider>(context);
    final accounts = accountsProvider.accounts;

    // Dynamically validate that selected IDs exist in the active accounts list
    if (_selectedAccountId != null && !accounts.any((acc) => acc.id == _selectedAccountId)) {
      _selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    }
    if (_targetAccountId != null && !accounts.any((acc) => acc.id == _targetAccountId)) {
      _targetAccountId = accounts.length > 1 ? accounts[1].id : null;
    }

    return SafeArea(
      child: SingleChildScrollView(
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
                      selected: isExpense && !isTransfer,
                      onSelected: (val) => setState(() {
                        isExpense = true;
                        isTransfer = false;
                      }),
                      selectedColor: Colors.redAccent.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isExpense && !isTransfer ? Colors.redAccent : theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Income'),
                      selected: !isExpense && !isTransfer,
                      onSelected: (val) => setState(() {
                        isExpense = false;
                        isTransfer = false;
                      }),
                      selectedColor: Colors.green.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: !isExpense && !isTransfer ? Colors.green : theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Transfer'),
                      selected: isTransfer,
                      onSelected: (val) => setState(() {
                        isTransfer = true;
                      }),
                      selectedColor: Colors.blueAccent.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isTransfer ? Colors.blueAccent : theme.textTheme.bodyMedium?.color,
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
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 16),

              // Account Selector(s)
              if (accounts.isEmpty) ...[
                Text(
                  'No accounts found. Please add an account first.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ] else if (isTransfer) ...[
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'From Account',
                    prefixIcon: const Icon(Icons.upload_outlined),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc.id,
                      child: Text(acc.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedAccountId = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _targetAccountId,
                  decoration: InputDecoration(
                    labelText: 'To Account',
                    prefixIcon: const Icon(Icons.download_outlined),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc.id,
                      child: Text(acc.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _targetAccountId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'Account',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc.id,
                      child: Text(acc.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedAccountId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Category Selector (only if not a transfer)
              if (!isTransfer) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    final cats = isExpense
                        ? categoryProvider.expenseCategories
                        : categoryProvider.incomeCategories;

                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length + 1,
                        itemBuilder: (context, index) {
                          if (index == cats.length) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CategoryManagementPage(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.settings_outlined),
                                      SizedBox(height: 8),
                                      Text(
                                        'Manage',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          final cat = cats[index];
                          final isSelected = _categoryController.text.toLowerCase() == cat.name.toLowerCase();

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _categoryController.text = cat.name;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 80,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surface,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CategoryIcon(
                                      categoryName: cat.name,
                                      isExpense: cat.isExpense,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

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
              const SizedBox(height: 16),

              // Date and Time picker row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(_selectedDateTime),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_outlined, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('HH:mm').format(_selectedDateTime),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
      ),
    );
  }
}
