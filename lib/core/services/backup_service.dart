import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/accounts/domain/models/account_model.dart';
import '../../features/categories/domain/models/category_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import 'hive_service.dart';

class BackupService {
  // Returns the target folder to store backups
  static Future<Directory> getBackupDirectory() async {
    Directory? baseDir;
    if (Platform.isAndroid) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          // Go up 4 levels to get /storage/emulated/0
          final rootPath = extDir.parent.parent.parent.parent.path;
          // Try writing to Downloads folder first as it's cleaner and highly visible
          final downloadsDir = Directory('$rootPath/Download/WalletBuddy');
          baseDir = downloadsDir;
        }
      } catch (e) {
        debugPrint('Error getting external storage directory: $e');
      }
    }
    
    // Fallback if iOS, desktop, or Android external storage access fails
    if (baseDir == null) {
      final docDir = await getApplicationDocumentsDirectory();
      baseDir = Directory('${docDir.path}/WalletBuddy');
    }

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  // Exports data to a JSON file
  static Future<File> exportData() async {
    final transactions = HiveService.transactionsBox.values.toList();
    final accounts = HiveService.accountsBox.values.toList();
    final categories = HiveService.categoriesBox.values.toList();
    
    final settings = <String, dynamic>{};
    for (var key in HiveService.settingsBox.keys) {
      settings[key.toString()] = HiveService.settingsBox.get(key);
    }

    final backupData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'settings': settings,
    };

    final jsonString = jsonEncode(backupData);
    final backupDir = await getBackupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final file = File('${backupDir.path}/wallet_buddy_backup_$timestamp.json');
    
    await file.writeAsString(jsonString);
    return file;
  }

  // Imports data from a JSON file
  static Future<void> importData(File file) async {
    final jsonString = await file.readAsString();
    final Map<String, dynamic> backupData = jsonDecode(jsonString);

    if (backupData['version'] != 1) {
      throw Exception('Unsupported backup version');
    }

    // Clear all boxes
    await HiveService.clearAll();
    await HiveService.settingsBox.clear();

    // Restore accounts
    if (backupData['accounts'] != null) {
      final accountsList = (backupData['accounts'] as List);
      final Map<String, AccountModel> accountsMap = {};
      for (var item in accountsList) {
        final account = AccountModel.fromJson(Map<String, dynamic>.from(item));
        accountsMap[account.id] = account;
      }
      await HiveService.accountsBox.putAll(accountsMap);
    }

    // Restore categories
    if (backupData['categories'] != null) {
      final categoriesList = (backupData['categories'] as List);
      final Map<String, CategoryModel> categoriesMap = {};
      for (var item in categoriesList) {
        final category = CategoryModel.fromJson(Map<String, dynamic>.from(item));
        categoriesMap[category.id] = category;
      }
      await HiveService.categoriesBox.putAll(categoriesMap);
    }

    // Restore transactions
    if (backupData['transactions'] != null) {
      final transactionsList = (backupData['transactions'] as List);
      final Map<String, TransactionModel> transactionsMap = {};
      for (var item in transactionsList) {
        final transaction = TransactionModel.fromJson(Map<String, dynamic>.from(item));
        transactionsMap[transaction.id] = transaction;
      }
      await HiveService.transactionsBox.putAll(transactionsMap);
    }

    // Restore settings
    if (backupData['settings'] != null) {
      final settingsMap = Map<String, dynamic>.from(backupData['settings']);
      await HiveService.settingsBox.putAll(settingsMap);
    }
  }

  // Lists all backup files in the backup directory, sorted by date descending
  static Future<List<File>> getBackupFiles() async {
    final backupDir = await getBackupDirectory();
    if (!await backupDir.exists()) return [];

    final List<File> files = [];
    final entities = await backupDir.list().toList();
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.json') && entity.path.contains('wallet_buddy_backup_')) {
        files.add(entity);
      }
    }

    // Sort by modified date descending
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }
}
