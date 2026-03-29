import 'package:flutter/material.dart';
import '../../../../core/services/hive_service.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StatisticsProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => _transactions;

  StatisticsProvider() {
    _loadTransactions();
    HiveService.transactionsBox.listenable().addListener(() {
      _loadTransactions();
    });
  }

  void _loadTransactions() {
    _transactions = HiveService.transactionsBox.values.toList();
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  /// Returns a list of unique 'yyyy-MM' strings for which we have transactions
  List<String> get availableMonths {
    final Set<String> months = {};
    for (var tx in _transactions) {
      final monthStr = "${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}";
      months.add(monthStr);
    }
    final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a));
    return sortedMonths;
  }

  List<TransactionModel> getTransactionsForMonth(String yearMonth) {
    return _transactions.where((tx) {
      final monthStr = "${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}";
      return monthStr == yearMonth;
    }).toList();
  }

  Map<String, double> getSummaryForMonth(String yearMonth) {
    double income = 0;
    double expense = 0;
    final txs = getTransactionsForMonth(yearMonth);
    
    for (var tx in txs) {
      if (tx.isExpense) {
        expense += tx.amount;
      } else {
        income += tx.amount;
      }
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }
}
