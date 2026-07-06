import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';
import '../../domain/models/budget_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';

class BudgetProvider with ChangeNotifier {
  final Box<BudgetModel> _budgetsBox = HiveService.budgetsBox;
  final Box<TransactionModel> _transactionsBox = HiveService.transactionsBox;

  List<BudgetModel> get budgets => _budgetsBox.values.toList();

  BudgetProvider() {
    _budgetsBox.listenable().addListener(_onBudgetsChanged);
    _transactionsBox.listenable().addListener(_onTransactionsChanged);
  }

  void _onBudgetsChanged() {
    notifyListeners();
  }

  void _onTransactionsChanged() {
    notifyListeners();
  }

  BudgetModel? getBudget(String categoryId) {
    try {
      return _budgetsBox.values.firstWhere((b) => b.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  Future<void> setBudget(String categoryId, double amount) async {
    final existingBudget = getBudget(categoryId);
    
    if (existingBudget != null) {
      if (amount <= 0) {
        await existingBudget.delete();
      } else {
        existingBudget.copyWith(amount: amount); // Since copyWith doesn't update Hive directly if not saved
        // We update the existing model manually and save
        await _budgetsBox.put(existingBudget.key, BudgetModel(
          id: existingBudget.id,
          categoryId: categoryId,
          amount: amount,
          isMonthly: existingBudget.isMonthly,
        ));
      }
    } else {
      if (amount > 0) {
        final newBudget = BudgetModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          categoryId: categoryId,
          amount: amount,
          isMonthly: true,
        );
        await _budgetsBox.add(newBudget);
      }
    }
    notifyListeners();
  }

  double getSpentAmount(String categoryId, DateTime month) {
    double spent = 0.0;
    final category = HiveService.categoriesBox.get(categoryId);
    final categoryName = category?.name ?? categoryId;

    for (var tx in _transactionsBox.values) {
      if (tx.category == categoryName && 
          tx.isExpense &&
          tx.timestamp.year == month.year &&
          tx.timestamp.month == month.month) {
        spent += tx.amount;
      }
    }
    return spent;
  }

  double getRemainingBudget(String categoryId, DateTime month) {
    final budget = getBudget(categoryId);
    if (budget == null) return 0.0;
    
    final spent = getSpentAmount(categoryId, month);
    return budget.amount - spent;
  }

  @override
  void dispose() {
    _budgetsBox.listenable().removeListener(_onBudgetsChanged);
    _transactionsBox.listenable().removeListener(_onTransactionsChanged);
    super.dispose();
  }
}
