import 'package:hive_flutter/hive_flutter.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import '../../features/accounts/domain/models/account_model.dart';

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String accountsBoxName = 'accounts';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountModelAdapter());
    }

    // Open boxes
    await Hive.openBox<TransactionModel>(transactionsBoxName);
    await Hive.openBox<AccountModel>(accountsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<TransactionModel> get transactionsBox => Hive.box<TransactionModel>(transactionsBoxName);
  static Box<AccountModel> get accountsBox => Hive.box<AccountModel>(accountsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);

  static Future<void> clearAll() async {
    await transactionsBox.clear();
    await accountsBox.clear();
  }
}
