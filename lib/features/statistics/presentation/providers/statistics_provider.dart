import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/hive_service.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum FilterPeriod { week, month, year }

class StatisticsProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  FilterPeriod _currentFilter = FilterPeriod.month;

  List<TransactionModel> get transactions => _transactions;
  FilterPeriod get currentFilter => _currentFilter;

  void setFilter(FilterPeriod filter) {
    _currentFilter = filter;
    notifyListeners();
  }

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

  String _getWeekYear(DateTime date) {
    final dayOfYear = int.parse(DateFormat("D").format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    return "${date.year}-W${woy.toString().padLeft(2, '0')}";
  }

  /// Returns a list of unique strings for which we have transactions based on filter
  List<String> get availablePeriods {
    final Set<String> periods = {};
    for (var tx in _transactions) {
      if (_currentFilter == FilterPeriod.year) {
        periods.add("${tx.timestamp.year}");
      } else if (_currentFilter == FilterPeriod.week) {
        periods.add(_getWeekYear(tx.timestamp));
      } else {
        // month
        periods.add("${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}");
      }
    }
    final sortedPeriods = periods.toList()..sort((a, b) => b.compareTo(a));
    return sortedPeriods;
  }

  List<TransactionModel> getTransactionsForPeriod(String period) {
    return _transactions.where((tx) {
      if (_currentFilter == FilterPeriod.year) {
        return "${tx.timestamp.year}" == period;
      } else if (_currentFilter == FilterPeriod.week) {
        return _getWeekYear(tx.timestamp) == period;
      } else {
        return "${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}" == period;
      }
    }).toList();
  }

  Map<String, double> getSummaryForPeriod(String period) {
    double income = 0;
    double expense = 0;
    final txs = getTransactionsForPeriod(period);
    
    for (var tx in txs) {
      if (tx.isExpense) {
        expense += tx.amount;
      } else {
        income += tx.amount;
      }
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }

  List<MapEntry<String, double>> getTopCategories(String period, {required bool isExpense}) {
    final txs = getTransactionsForPeriod(period).where((tx) => tx.isExpense == isExpense && tx.category != 'Transfer');
    final Map<String, double> categoryMap = {};
    for (var tx in txs) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
    }
    final sorted = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  Map<int, double> getPeriodicExpenses(String period) {
    final txs = getTransactionsForPeriod(period).where((tx) => tx.isExpense && tx.category != 'Transfer');
    final Map<int, double> periodicData = {};
    for (var tx in txs) {
      int key;
      if (_currentFilter == FilterPeriod.year) {
        key = tx.timestamp.month; // grouped by month
      } else if (_currentFilter == FilterPeriod.week) {
        key = tx.timestamp.weekday; // grouped by day of week
      } else {
        key = tx.timestamp.day; // grouped by day of month
      }
      periodicData[key] = (periodicData[key] ?? 0) + tx.amount;
    }
    return periodicData;
  }
}
