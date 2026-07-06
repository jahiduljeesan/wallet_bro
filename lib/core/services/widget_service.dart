import 'package:home_widget/home_widget.dart';
import 'hive_service.dart';
import '../utils/currency_formatter.dart';

class WidgetService {
  /// Recalculates the Cash account balance and updates the Android home screen widget.
  static Future<void> updateHomeWidget() async {
    try {
      final cashAccount = HiveService.accountsBox.get('cash_account');
      if (cashAccount == null) return;

      double balance = cashAccount.initialBalance;
      final transactions = HiveService.transactionsBox.values.where((tx) => tx.accountId == 'cash_account');
      
      for (var tx in transactions) {
        if (tx.isExpense) {
          balance -= tx.amount;
        } else {
          balance += tx.amount;
        }
      }

      final formattedBalance = CurrencyFormatter.format(balance);

      await HomeWidget.saveWidgetData<String>('cash_balance', formattedBalance);
      await HomeWidget.updateWidget(
        name: 'WalletBroWidgetProvider',
        androidName: 'WalletBroWidgetProvider',
      );

      // --- Analytics Widget Update ---
      double income = 0.0;
      double expense = 0.0;
      final now = DateTime.now();
      
      for (var tx in HiveService.transactionsBox.values) {
        if (tx.timestamp.year == now.year && tx.timestamp.month == now.month) {
          if (tx.isExpense) {
            expense += tx.amount;
          } else {
            income += tx.amount;
          }
        }
      }

      // --- Budget Update ---
      double totalBudget = 0.0;
      double totalBudgetSpent = 0.0;
      
      final activeBudgets = HiveService.budgetsBox.values.where((b) => b.amount > 0).toList();
      for (var budget in activeBudgets) {
        totalBudget += budget.amount;
        
        final category = HiveService.categoriesBox.get(budget.categoryId);
        final categoryName = category?.name ?? budget.categoryId;

        // Calculate spent for this budget category
        for (var tx in HiveService.transactionsBox.values) {
          if (tx.category == categoryName && 
              tx.isExpense &&
              tx.timestamp.year == now.year &&
              tx.timestamp.month == now.month) {
            totalBudgetSpent += tx.amount;
          }
        }
      }

      int budgetProgress = totalBudget > 0 ? ((totalBudgetSpent / totalBudget).clamp(0.0, 1.0) * 100).toInt() : 0;

      await HomeWidget.saveWidgetData<String>('monthly_income', CurrencyFormatter.format(income));
      await HomeWidget.saveWidgetData<String>('monthly_expense', CurrencyFormatter.format(expense));
      await HomeWidget.saveWidgetData<String>('monthly_budget_text', '৳${totalBudgetSpent.toStringAsFixed(0)} / ৳${totalBudget.toStringAsFixed(0)}');
      await HomeWidget.saveWidgetData<int>('monthly_budget_progress', budgetProgress);
      await HomeWidget.updateWidget(
        name: 'AnalyticsWidgetProvider',
        androidName: 'AnalyticsWidgetProvider',
      );
    } catch (e) {
      // Ignore widget update errors silently in release
    }
  }
}
