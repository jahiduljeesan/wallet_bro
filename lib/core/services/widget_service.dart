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

      await HomeWidget.saveWidgetData<String>('monthly_income', CurrencyFormatter.format(income));
      await HomeWidget.saveWidgetData<String>('monthly_expense', CurrencyFormatter.format(expense));
      await HomeWidget.updateWidget(
        name: 'AnalyticsWidgetProvider',
        androidName: 'AnalyticsWidgetProvider',
      );
    } catch (e) {
      // Ignore widget update errors silently in release
    }
  }
}
