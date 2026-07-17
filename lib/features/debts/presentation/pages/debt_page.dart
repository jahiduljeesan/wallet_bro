import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../../domain/models/debt_model.dart';
import 'add_debt_sheet.dart';
import '../../../../core/services/hive_service.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DebtProvider(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Debts & Loans'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'I Owe'),
                Tab(text: 'Owed To Me'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [_DebtList(isDebtTab: true), _DebtList(isDebtTab: false)],
          ),
          floatingActionButton: Builder(
            builder: (context) {
              return FloatingActionButton(
                onPressed: () {
                  final provider = Provider.of<DebtProvider>(
                    context,
                    listen: false,
                  );
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddDebtSheet(provider: provider),
                  );
                },
                child: const Icon(Icons.add),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final bool isDebtTab;

  const _DebtList({required this.isDebtTab});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DebtProvider>(context);
    final items = isDebtTab ? provider.iOwe : provider.owedToMe;

    if (items.isEmpty) {
      return Center(
        child: Text(
          isDebtTab ? 'No debts right now. Yay!' : 'No one owes you money.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final debt = items[index];
        return _DebtTile(debt: debt, provider: provider);
      },
    );
  }
}

class _DebtTile extends StatelessWidget {
  final DebtModel debt;
  final DebtProvider provider;

  const _DebtTile({required this.debt, required this.provider});

  void _showPaymentDialog(BuildContext context) {
    final controller = TextEditingController(text: debt.remainingAmount.toStringAsFixed(0));
    final noteController = TextEditingController();
    
    final accounts = HiveService.accountsBox.values.toList();
    String selectedAccountId = debt.accountId;
    if (accounts.isNotEmpty && !accounts.any((a) => a.id == selectedAccountId)) {
      selectedAccountId = accounts.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Record Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedAccountId,
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
                      setState(() => selectedAccountId = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final amount = double.tryParse(controller.text) ?? 0;
                  if (amount > 0) {
                    provider.payPartialAmount(debt.id, amount, note: noteController.text, accountId: selectedAccountId);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, y').format(debt.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Record'),
              content: const Text('Are you sure you want to delete this record?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    provider.deleteDebt(debt.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: debt.isSettled
                ? Colors.grey.withValues(alpha: 0.2)
                : (debt.isDebt
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : Colors.greenAccent.withValues(alpha: 0.1)),
            child: Icon(
              debt.isSettled
                  ? Icons.check_circle
                  : (debt.isDebt ? Icons.arrow_downward : Icons.arrow_upward),
              color: debt.isSettled
                  ? Colors.grey
                  : (debt.isDebt ? Colors.redAccent : Colors.green),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  debt.personName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: debt.isSettled ? TextDecoration.lineThrough : null,
                    color: debt.isSettled ? Colors.grey : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddDebtSheet(provider: provider, debt: debt),
                  );
                },
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (debt.note.isNotEmpty) Text(debt.note),
              Text(dateStr, style: const TextStyle(fontSize: 12)),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '৳${debt.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: debt.isSettled ? TextDecoration.lineThrough : null,
                  color: debt.isSettled
                      ? Colors.grey
                      : (debt.isDebt ? Colors.redAccent : Colors.green),
                ),
              ),
              if (debt.calculatedPaidAmount > 0 && !debt.isSettled)
                Text(
                  'Left: ৳${debt.remainingAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (debt.isSettled)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Settled',
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          children: [
            const Divider(),
            if (debt.payments.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              ...debt.payments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('MMM d, y').format(p.timestamp), style: const TextStyle(fontSize: 12)),
                        if (p.note.isNotEmpty) Text(p.note, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Text('৳${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
            if (!debt.isSettled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context),
                  icon: const Icon(Icons.payment),
                  label: const Text('Add Partial Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
