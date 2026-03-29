import 'package:flutter/material.dart';
import '../../../../core/services/hive_service.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DashboardProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => _transactions;

  double get totalBalance {
    double temp = 0;
    for (var tx in _transactions) {
      if (tx.isExpense) {
        temp -= tx.amount;
      } else {
        temp += tx.amount;
      }
    }
    return temp;
  }

  double get currentMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((tx) => !tx.isExpense && tx.timestamp.year == now.year && tx.timestamp.month == now.month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get currentMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.isExpense && tx.timestamp.year == now.year && tx.timestamp.month == now.month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }


  DashboardProvider() {
    _loadTransactions();
    // Listen to Hive box changes
    HiveService.transactionsBox.listenable().addListener(() {
      _loadTransactions();
    });
  }

  void _loadTransactions() {
    final box = HiveService.transactionsBox;
    _transactions = box.values.toList();
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  void addTransaction(TransactionModel transaction) {
    HiveService.transactionsBox.put(transaction.id, transaction);
  }

  void deleteTransaction(String id) {
    HiveService.transactionsBox.delete(id);
  }
}
