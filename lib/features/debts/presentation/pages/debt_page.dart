import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../../domain/models/debt_model.dart';
import 'add_debt_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, y').format(debt.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: debt.isSettled
              ? Colors.grey.withOpacity(0.2)
              : (debt.isDebt
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.greenAccent.withOpacity(0.1)),
          child: Icon(
            debt.isSettled
                ? Icons.check_circle
                : (debt.isDebt ? Icons.arrow_downward : Icons.arrow_upward),
            color: debt.isSettled
                ? Colors.grey
                : (debt.isDebt ? Colors.redAccent : Colors.green),
          ),
        ),
        title: Text(
          debt.personName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: debt.isSettled ? TextDecoration.lineThrough : null,
            color: debt.isSettled ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '${debt.note.isNotEmpty ? '${debt.note}\n' : ''}$dateStr',
        ),
        isThreeLine: debt.note.isNotEmpty,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
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
            const SizedBox(height: 4),
            InkWell(
              onTap: () => provider.toggleSettled(debt.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: debt.isSettled
                      ? Colors.green.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  debt.isSettled ? 'Settled' : 'Mark Settled',
                  style: TextStyle(
                    fontSize: 12,
                    color: debt.isSettled
                        ? Colors.green
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Record'),
              content: const Text(
                'Are you sure you want to delete this record?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    provider.deleteDebt(debt.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
