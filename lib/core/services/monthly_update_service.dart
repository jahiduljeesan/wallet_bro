import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../features/accounts/domain/models/account_model.dart';
import '../../features/statistics/domain/models/monthly_summary_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import 'backup_service.dart';
import 'hive_service.dart';

class MonthlyUpdateService {
  static const String _lastOpenedMonthKey = 'last_opened_month';

  /// Runs on startup. Checks if month changed and performs rollover if needed.
  static Future<void> checkAndRunMonthlyUpdate() async {
    final now = DateTime.now();
    final currentMonthId = DateFormat('yyyy-MM').format(now);

    final String? lastOpenedMonth = HiveService.settingsBox.get(
      _lastOpenedMonthKey,
    );

    if (lastOpenedMonth == null) {
      // First time running, just save current month
      await HiveService.settingsBox.put(_lastOpenedMonthKey, currentMonthId);
      return;
    }

    if (currentMonthId != lastOpenedMonth) {
      // Month changed, perform rollover for lastOpenedMonth
      await _performMonthlyRollover(lastOpenedMonth);

      // Update to current month
      await HiveService.settingsBox.put(_lastOpenedMonthKey, currentMonthId);
    }
  }

  static Future<void> _performMonthlyRollover(String monthId) async {
    final transactions = HiveService.transactionsBox.values.toList();
    final accounts = HiveService.accountsBox.values.toList();

    // Filter transactions for the old month
    final oldMonthTxs = transactions.where((tx) {
      return DateFormat('yyyy-MM').format(tx.timestamp) == monthId;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryBreakdown = {};

    for (var tx in oldMonthTxs) {
      if (tx.isExpense) {
        totalExpense += tx.amount;
      } else {
        totalIncome += tx.amount;
      }

      categoryBreakdown[tx.category] =
          (categoryBreakdown[tx.category] ?? 0) + tx.amount;
    }

    // Save summary
    final summary = MonthlySummaryModel(
      id: monthId,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categoryBreakdown: categoryBreakdown,
    );
    await HiveService.monthlySummariesBox.put(monthId, summary);

    // Calculate remaining positive balance of cash_account specifically
    double cashRemaining = 0;
    
    // Find cash account
    AccountModel? cashAccount;
    try {
      cashAccount = accounts.firstWhere((acc) => acc.id == 'cash_account');
    } catch (_) {
      cashAccount = AccountModel(
        id: 'cash_account',
        name: 'Cash',
        type: 'Cash',
        initialBalance: 0,
      );
      await HiveService.accountsBox.put(cashAccount.id, cashAccount);
    }

    double cashBalance = cashAccount.initialBalance;
    for (var tx in transactions) {
      if (tx.accountId == 'cash_account') {
        if (tx.isExpense) {
          cashBalance -= tx.amount;
        } else {
          cashBalance += tx.amount;
        }
      }
    }
    if (cashBalance > 0) {
      cashRemaining = cashBalance;
    }

    // Update Savings Account Initial Balance
    AccountModel? savingsAccount;
    try {
      savingsAccount = accounts.firstWhere(
        (acc) => acc.id == 'savings_account',
      );
    } catch (_) {
      savingsAccount = AccountModel(
        id: 'savings_account',
        name: 'Savings',
        type: 'Bank',
        initialBalance: 0,
      );
      await HiveService.accountsBox.put(savingsAccount.id, savingsAccount);
    }

    // Calculate current true balance of Savings
    double currentSavingsBalance = savingsAccount.initialBalance;
    for (var tx in transactions) {
      if (tx.accountId == savingsAccount.id) {
        if (tx.isExpense) {
          currentSavingsBalance -= tx.amount;
        } else {
          currentSavingsBalance += tx.amount;
        }
      }
    }

    // Backup the full dataset BEFORE clearing transactions
    try {
      await BackupService.exportData();
    } catch (e) {
      // Ignore backup errors
    }

    // Update initial balances for all accounts:
    // - cash_account: reset to 0
    // - savings_account: handled below
    // - custom accounts: set to their current live balance so it carries over
    for (var acc in accounts) {
      if (acc.id == 'cash_account') {
        await HiveService.accountsBox.put(
          acc.id,
          acc.copyWith(initialBalance: 0),
        );
      } else if (acc.id == 'savings_account') {
        // Handled below
      } else {
        double customBalance = acc.initialBalance;
        for (var tx in transactions) {
          if (tx.accountId == acc.id) {
            if (tx.isExpense) {
              customBalance -= tx.amount;
            } else {
              customBalance += tx.amount;
            }
          }
        }
        await HiveService.accountsBox.put(
          acc.id,
          acc.copyWith(initialBalance: customBalance),
        );
      }
    }

    // Update savings account initial balance with the rollover amount
    final updatedSavings = savingsAccount.copyWith(
      initialBalance: currentSavingsBalance + cashRemaining,
    );
    await HiveService.accountsBox.put(updatedSavings.id, updatedSavings);

    // Completely clear all transactions to start fresh for the new month
    await HiveService.transactionsBox.clear();
  }
}
