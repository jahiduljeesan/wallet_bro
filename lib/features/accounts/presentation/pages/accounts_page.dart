import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accounts_provider.dart';
import 'add_account_sheet.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AddAccountSheet(),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'mobile':
        return Icons.phone_iphone_outlined;
      case 'cash':
      default:
        return Icons.money_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AccountsProvider>(
        builder: (context, accountsProvider, child) {
          final accounts = accountsProvider.accounts;

          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts added yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final liveBalance = accountsProvider.getAccountBalance(account.id);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                ),
                color: theme.colorScheme.surface,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onLongPress: () {
                    // Quick delete option
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: Text('Are you sure you want to delete ${account.name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              accountsProvider.deleteAccount(account.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(account.type),
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                account.type,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${liveBalance.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: liveBalance < 0 ? theme.colorScheme.error : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
