import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';
import '../../domain/models/debt_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/debt_payment_model.dart';

class DebtProvider extends ChangeNotifier {
  List<DebtModel> _debts = [];
  
  List<DebtModel> get debts => _debts;
  List<DebtModel> get iOwe => _debts.where((d) => d.isDebt).toList();
  List<DebtModel> get owedToMe => _debts.where((d) => !d.isDebt).toList();

  DebtProvider() {
    _loadDebts();
    HiveService.debtsBox.listenable().addListener(() {
      _loadDebts();
    });
  }

  void _loadDebts() {
    _debts = HiveService.debtsBox.values.toList();
    _debts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> addDebt({
    String? id, // If provided, update existing
    required String personName,
    required double amount,
    required bool isDebt,
    String note = '',
    String accountId = 'cash_account',
  }) async {
    final bool isUpdate = id != null;
    final debtId = id ?? const Uuid().v4();
    final now = DateTime.now();

    if (isUpdate) {
      final existingDebt = HiveService.debtsBox.get(debtId);
      if (existingDebt != null) {
        final updatedDebt = existingDebt.copyWith(
          personName: personName,
          amount: amount,
          isDebt: isDebt,
          note: note,
          accountId: accountId,
        );
        await HiveService.debtsBox.put(debtId, updatedDebt);
      }
    } else {
      final newDebt = DebtModel(
        id: debtId,
        personName: personName,
        amount: amount,
        isDebt: isDebt,
        timestamp: now,
        note: note,
        accountId: accountId,
      );
      await HiveService.debtsBox.put(debtId, newDebt);

      // Create transaction for selected Account
      final selectedAccount = HiveService.accountsBox.get(accountId);
      if (selectedAccount != null) {
        final tx = TransactionModel(
          id: const Uuid().v4(),
          amount: amount,
          category: isDebt ? 'Borrowed (Debt)' : 'Lent (Loan)',
          note: note.isNotEmpty ? note : 'Debt with $personName',
          timestamp: now,
          createdBy: 'debt_system',
          accountId: accountId,
          isExpense: !isDebt, // If Lent (Owed to me), it's an expense (cash out). If Borrowed (I Owe), it's income (cash in).
        );
        await HiveService.transactionsBox.put(tx.id, tx);
      }
    }
  }

  Future<void> payPartialAmount(String id, double payAmount, {String note = '', String accountId = 'cash_account'}) async {
    final debt = HiveService.debtsBox.get(id);
    if (debt != null) {
      final newPayment = DebtPaymentModel(
        id: const Uuid().v4(),
        amount: payAmount,
        timestamp: DateTime.now(),
        note: note,
        accountId: accountId,
      );
      
      final updatedPayments = List<DebtPaymentModel>.from(debt.payments)..add(newPayment);
      final newPaidAmount = debt.paidAmount + payAmount;
      final isSettled = updatedPayments.fold(0.0, (sum, p) => sum + p.amount) + debt.paidAmount >= debt.amount;
      
      final updatedDebt = debt.copyWith(
        paidAmount: newPaidAmount,
        payments: updatedPayments,
        isSettled: isSettled,
      );
      await HiveService.debtsBox.put(id, updatedDebt);

      // Create transaction for selected Account for the payment
      final selectedAccount = HiveService.accountsBox.get(accountId);
      if (selectedAccount != null) {
        final txNote = note.isNotEmpty ? note : 'Payment for debt with ${debt.personName}';
        final tx = TransactionModel(
          id: const Uuid().v4(),
          amount: payAmount,
          category: debt.isDebt ? 'Debt Repayment' : 'Loan Collection',
          note: txNote,
          timestamp: DateTime.now(),
          createdBy: 'debt_system',
          accountId: accountId,
          isExpense: debt.isDebt, // If paying back what I owe, it's an expense (cash out). If collecting, it's income (cash in).
        );
        await HiveService.transactionsBox.put(tx.id, tx);
      }
    }
  }

  Future<void> toggleSettled(String id) async {
    final debt = HiveService.debtsBox.get(id);
    if (debt != null) {
      final updatedDebt = debt.copyWith(isSettled: !debt.isSettled);
      await HiveService.debtsBox.put(id, updatedDebt);
    }
  }

  Future<void> deleteDebt(String id) async {
    await HiveService.debtsBox.delete(id);
  }
}
