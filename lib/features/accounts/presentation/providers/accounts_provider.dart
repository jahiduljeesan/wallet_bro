import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';
import '../../domain/models/account_model.dart';

class AccountsProvider extends ChangeNotifier {
  List<AccountModel> _accounts = [];

  List<AccountModel> get accounts => _accounts;

  AccountsProvider() {
    _loadAccounts();
    // Listen to Hive box changes
    HiveService.accountsBox.listenable().addListener(() {
      _loadAccounts();
    });
    // Also listen to transactions box, because account balance depends on transactions
    HiveService.transactionsBox.listenable().addListener(() {
      notifyListeners(); // Just notify to recalculate balances on the UI
    });
  }

  void _loadAccounts() {
    final box = HiveService.accountsBox;
    _accounts = box.values.toList();
    notifyListeners();
  }

  void addAccount(AccountModel account) {
    HiveService.accountsBox.put(account.id, account);
  }

  void updateAccount(AccountModel account) {
    HiveService.accountsBox.put(account.id, account);
  }

  void deleteAccount(String id) {
    HiveService.accountsBox.delete(id);
    
    // Optional: cascade delete transactions associated with this account?
    // For now, let's keep it safe and just delete the account.
  }

  double getAccountBalance(String accountId) {
    final account = _accounts.firstWhere(
      (acc) => acc.id == accountId,
      orElse: () => AccountModel(id: '', name: 'Unknown', type: 'Cash', initialBalance: 0),
    );

    if (account.id.isEmpty) return 0.0;

    double balance = account.initialBalance;

    // Calculate sum of transactions for this account
    final transactions = HiveService.transactionsBox.values.where((tx) => tx.accountId == accountId);
    
    for (var tx in transactions) {
      if (tx.isExpense) {
        balance -= tx.amount;
      } else {
        balance += tx.amount;
      }
    }

    return balance;
  }
}
