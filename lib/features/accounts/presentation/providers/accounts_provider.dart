import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/widget_service.dart';
import '../../domain/models/account_model.dart';

class AccountsProvider extends ChangeNotifier {
  List<AccountModel> _accounts = [];

  List<AccountModel> get accounts => _accounts;

  AccountsProvider() {
    _loadAccounts();
    // Listen to Hive box changes
    HiveService.accountsBox.listenable().addListener(() {
      _loadAccounts();
      WidgetService.updateHomeWidget();
    });
    // Also listen to transactions box, because account balance depends on transactions
    HiveService.transactionsBox.listenable().addListener(() {
      notifyListeners(); // Just notify to recalculate balances on the UI
      WidgetService.updateHomeWidget();
    });
  }

  void _loadAccounts() {
    final box = HiveService.accountsBox;
    _accounts = box.values.toList();
    
    // Migration for order field if everything is 0
    if (_accounts.isNotEmpty && _accounts.every((a) => a.order == 0)) {
      int nextOrder = 2;
      for (int i = 0; i < _accounts.length; i++) {
        var acc = _accounts[i];
        if (acc.id == 'cash_account') {
          _accounts[i] = acc.copyWith(order: 0);
        } else if (acc.id == 'savings_account') {
          _accounts[i] = acc.copyWith(order: 1);
        } else {
          _accounts[i] = acc.copyWith(order: nextOrder++);
        }
        HiveService.accountsBox.put(_accounts[i].id, _accounts[i]);
      }
    }
    
    _accounts.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  void reorderAccounts(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final account = _accounts.removeAt(oldIndex);
    _accounts.insert(newIndex, account);
    
    // Update all orders and save to Hive silently (avoiding infinite loop if we listen to box)
    for (int i = 0; i < _accounts.length; i++) {
      _accounts[i] = _accounts[i].copyWith(order: i);
      HiveService.accountsBox.put(_accounts[i].id, _accounts[i]);
    }
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
