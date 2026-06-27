import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import '../../features/accounts/domain/models/account_model.dart';
import '../../features/categories/domain/models/category_model.dart';

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String accountsBoxName = 'accounts';
  static const String settingsBoxName = 'settings';
  static const String categoriesBoxName = 'categories';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }

    // Open boxes
    await Hive.openBox<TransactionModel>(transactionsBoxName);
    await Hive.openBox<AccountModel>(accountsBoxName);
    await Hive.openBox(settingsBoxName);
    
    final categoriesBox = await Hive.openBox<CategoryModel>(categoriesBoxName);
    if (categoriesBox.isEmpty) {
      await _seedCategories(categoriesBox);
    }
  }

  static Box<TransactionModel> get transactionsBox => Hive.box<TransactionModel>(transactionsBoxName);
  static Box<AccountModel> get accountsBox => Hive.box<AccountModel>(accountsBoxName);
  static Box<CategoryModel> get categoriesBox => Hive.box<CategoryModel>(categoriesBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);

  static Future<void> _seedCategories(Box<CategoryModel> box) async {
    final List<CategoryModel> defaults = [
      // Expense
      CategoryModel(id: 'exp_meal', name: 'Meal', isExpense: true, iconPath: 'assets/images/categories/food.png', iconCodePoint: Icons.restaurant.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_food', name: 'Food', isExpense: true, iconPath: 'assets/images/categories/food.png', iconCodePoint: Icons.restaurant.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_bills', name: 'Bills', isExpense: true, iconCodePoint: Icons.receipt_long.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_rent', name: 'Rent', isExpense: true, iconCodePoint: Icons.home.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_medicine', name: 'Medicine', isExpense: true, iconCodePoint: Icons.medical_services.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_education', name: 'Education', isExpense: true, iconCodePoint: Icons.school.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_travel', name: 'Travel', isExpense: true, iconPath: 'assets/images/categories/transport.png', iconCodePoint: Icons.flight.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_shopping', name: 'Shopping', isExpense: true, iconPath: 'assets/images/categories/shopping.png', iconCodePoint: Icons.shopping_bag.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_beauty', name: 'Beauty', isExpense: true, iconCodePoint: Icons.face.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_entertainment', name: 'Entertainment', isExpense: true, iconCodePoint: Icons.movie.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_transportation', name: 'Transportation', isExpense: true, iconPath: 'assets/images/categories/transport.png', iconCodePoint: Icons.directions_car.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_gifts', name: 'Gifts', isExpense: true, iconCodePoint: Icons.card_giftcard.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_subscriptions', name: 'Subscriptions', isExpense: true, iconCodePoint: Icons.subscriptions.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_donation', name: 'Donation', isExpense: true, iconCodePoint: Icons.volunteer_activism.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'exp_others', name: 'Others', isExpense: true, iconPath: 'assets/images/categories/others.png', iconCodePoint: Icons.more_horiz.codePoint, iconFontFamily: 'MaterialIcons'),

      // Income
      CategoryModel(id: 'inc_fixed', name: 'Fixed', isExpense: false, iconPath: 'assets/images/categories/income.png', iconCodePoint: Icons.account_balance.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'inc_variable', name: 'Variable', isExpense: false, iconPath: 'assets/images/categories/income.png', iconCodePoint: Icons.monetization_on.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'inc_passive', name: 'Passive', isExpense: false, iconPath: 'assets/images/categories/income.png', iconCodePoint: Icons.trending_up.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'inc_bonuses', name: 'Bonuses', isExpense: false, iconPath: 'assets/images/categories/income.png', iconCodePoint: Icons.card_giftcard.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'inc_refund', name: 'Refund', isExpense: false, iconPath: 'assets/images/categories/income.png', iconCodePoint: Icons.settings_backup_restore.codePoint, iconFontFamily: 'MaterialIcons'),
      CategoryModel(id: 'inc_others', name: 'Others', isExpense: false, iconPath: 'assets/images/categories/others.png', iconCodePoint: Icons.more_horiz.codePoint, iconFontFamily: 'MaterialIcons'),
    ];

    for (var cat in defaults) {
      await box.put(cat.id, cat);
    }
  }

  static Future<void> clearAll() async {
    await transactionsBox.clear();
    await accountsBox.clear();
    await categoriesBox.clear();
  }
}
