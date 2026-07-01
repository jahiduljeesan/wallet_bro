import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';
import '../../domain/models/debt_model.dart';
import 'package:uuid/uuid.dart';

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
    required String personName,
    required double amount,
    required bool isDebt,
    String note = '',
  }) async {
    final newDebt = DebtModel(
      id: const Uuid().v4(),
      personName: personName,
      amount: amount,
      isDebt: isDebt,
      timestamp: DateTime.now(),
      note: note,
    );
    await HiveService.debtsBox.put(newDebt.id, newDebt);
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
