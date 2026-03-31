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

  Map<String, double> getCategoryData() {
    final Map<String, double> data = {};
    for (var tx in _transactions.where((t) => t.isExpense)) {
      data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
    }
    return data;
  }

  List<MapEntry<DateTime, double>> getWeeklySpendingData() {
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) => DateTime(now.year, now.month, now.day).subtract(Duration(days: index))).reversed.toList();
    
    final Map<DateTime, double> data = {for (var date in last7Days) date: 0.0};
    
    for (var tx in _transactions.where((t) => t.isExpense)) {
      final txDate = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      if (data.containsKey(txDate)) {
        data[txDate] = data[txDate]! + tx.amount;
      }
    }
    return data.entries.toList();
  }

  String get topCategory {
    final catData = getCategoryData();
    if (catData.isEmpty) return 'N/A';
    return catData.entries.fold(catData.entries.first, (a, b) => a.value > b.value ? a : b).key;
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
