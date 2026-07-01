import 'package:flutter/material.dart';
import '../../../../core/services/open_router_service.dart';
import 'dart:convert';
import '../../../../core/services/hive_service.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../accounts/domain/models/account_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hi! I'm your AI financial assistant. Tell me what you spent today.", isUser: false, timestamp: DateTime.now()),
  ];

  List<ChatMessage> get messages => _messages;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final OpenRouterService _openRouterService = OpenRouterService();

  String _resolveAccountId(String accountRef) {
    final accounts = HiveService.accountsBox.values.toList();
    if (accounts.isEmpty) return 'cash_account';

    final ref = accountRef.trim().toLowerCase();
    if (ref.isEmpty) return accounts.first.id;

    // 1. Exact ID match
    if (accounts.any((acc) => acc.id == accountRef)) {
      return accountRef;
    }

    // 2. Case-insensitive ID match
    final idMatch = accounts.where((acc) => acc.id.toLowerCase() == ref);
    if (idMatch.isNotEmpty) {
      return idMatch.first.id;
    }

    // 3. Case-insensitive Name match
    final nameMatch = accounts.where((acc) => acc.name.toLowerCase() == ref);
    if (nameMatch.isNotEmpty) {
      return nameMatch.first.id;
    }

    // 4. Substring Name match
    final substringMatch = accounts.where((acc) => 
      acc.name.toLowerCase().contains(ref) ||
      ref.contains(acc.name.toLowerCase())
    );
    if (substringMatch.isNotEmpty) {
      return substringMatch.first.id;
    }

    // 5. Fallback to first account
    return accounts.first.id;
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    // User message
    _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    _isLoading = true;
    notifyListeners();

    // API call
    final response = await _openRouterService.generateResponse(text);
    
    _isLoading = false;
    
    String displayText = response;
    
    try {
      // Sometimes AI wraps JSON in markdown blocks
      String jsonStr = response;
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }
      
      // Attempt to decode
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      int createdAccountsCount = 0;
      int addedCount = 0;
      int transferCount = 0;

      // 1. Process new accounts first
      if (data.containsKey('newAccounts')) {
        final List<dynamic> newAccList = data['newAccounts'];
        for (var item in newAccList) {
          final String name = item['name'] ?? '';
          if (name.trim().isEmpty) continue;
          
          // Check if it already exists by name or ID (to avoid duplicates)
          final existing = HiveService.accountsBox.values.any((acc) =>
              acc.name.toLowerCase() == name.toLowerCase() ||
              acc.id.toLowerCase() == name.replaceAll(' ', '_').toLowerCase());
              
          if (!existing) {
            final String type = item['type'] ?? 'Cash';
            final double initialBal = (item['initialBalance'] is num)
                ? (item['initialBalance'] as num).toDouble()
                : double.tryParse(item['initialBalance'].toString()) ?? 0.0;
                
            final String newId = name.replaceAll(' ', '_').toLowerCase() + '_${DateTime.now().millisecondsSinceEpoch}';
            final newAcc = AccountModel(
              id: newId,
              name: name,
              type: type,
              initialBalance: initialBal,
            );
            HiveService.accountsBox.put(newAcc.id, newAcc);
            createdAccountsCount++;
          }
        }
      }

      // 2. Process command models (transactions)
      if (data.containsKey('parsedCommandModels')) {
        final List<dynamic> models = data['parsedCommandModels'];
        for (var item in models) {
          String category = item['category'] ?? 'Others';
          double amount = (item['amount'] is num) 
              ? (item['amount'] as num).toDouble() 
              : double.tryParse(item['amount'].toString()) ?? 0.0;
          String type = item['type'] ?? 'Expense';
          String remark = item['remark'] ?? '';
          String accountRef = item['accountId'] ?? '';
          
          bool isExpense = type.toLowerCase() != 'income';
          String resolvedAccountId = _resolveAccountId(accountRef);
          
          final tx = TransactionModel(
            id: DateTime.now().microsecondsSinceEpoch.toString() + addedCount.toString(),
            amount: amount,
            category: category,
            note: remark,
            timestamp: DateTime.now(),
            createdBy: 'AI',
            accountId: resolvedAccountId,
            isExpense: isExpense,
          );
          
          HiveService.transactionsBox.put(tx.id, tx);
          addedCount++;
        }
      }

      // 3. Process transfers
      if (data.containsKey('transfers')) {
        final List<dynamic> transfers = data['transfers'];
        for (var item in transfers) {
          String fromAccount = item['fromAccount'] ?? '';
          String toAccount = item['toAccount'] ?? '';
          double amount = (item['amount'] is num) 
              ? (item['amount'] as num).toDouble() 
              : double.tryParse(item['amount'].toString()) ?? 0.0;

          if (fromAccount.isNotEmpty && toAccount.isNotEmpty && amount > 0) {
            final resolvedFrom = _resolveAccountId(fromAccount);
            final resolvedTo = _resolveAccountId(toAccount);

            if (resolvedFrom == resolvedTo) {
              continue; // Prevent transfers within the same account
            }

            final fromAccName = HiveService.accountsBox.get(resolvedFrom)?.name ?? resolvedFrom;
            final toAccName = HiveService.accountsBox.get(resolvedTo)?.name ?? resolvedTo;

            final now = DateTime.now();
            final outTx = TransactionModel(
              id: now.microsecondsSinceEpoch.toString() + 'out',
              amount: amount,
              category: 'Transfer',
              note: 'Transfer to $toAccName',
              timestamp: now.subtract(const Duration(seconds: 1)),
              createdBy: 'AI',
              accountId: resolvedFrom,
              isExpense: true,
            );
            final inTx = TransactionModel(
              id: now.microsecondsSinceEpoch.toString() + 'in',
              amount: amount,
              category: 'Transfer',
              note: 'Transfer from $fromAccName',
              timestamp: now,
              createdBy: 'AI',
              accountId: resolvedTo,
              isExpense: false,
            );
            HiveService.transactionsBox.put(outTx.id, outTx);
            HiveService.transactionsBox.put(inTx.id, inTx);
            transferCount++;
          }
        }
      }

      if (addedCount > 0 || transferCount > 0 || createdAccountsCount > 0) {
        String advice = data['advice'] ?? '';
        List<String> successMessages = [];
        if (createdAccountsCount > 0) successMessages.add("🏦 Created $createdAccountsCount new account(s).");
        if (addedCount > 0) successMessages.add("✅ Successfully added $addedCount transaction(s).");
        if (transferCount > 0) successMessages.add("✅ Successfully executed $transferCount transfer(s).");
        
        displayText = "${successMessages.join('\n')}\n\n$advice".trim();
      } else if (data.containsKey('advice')) {
        // Empty transactions, just show advice
        displayText = data['advice'] ?? response;
      }
    } catch (e) {
      // Parsing failed or it wasn't JSON, just display the raw text
      displayText = response;
    }

    _messages.add(ChatMessage(
      text: displayText,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
