import 'package:flutter/material.dart';
import '../../../../core/services/open_router_service.dart';
import 'dart:convert';
import '../../../../core/services/hive_service.dart';
import '../../../transactions/domain/models/transaction_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hi! I'm your AI financial assistant. Tell me what you spent today.",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final OpenRouterService _openRouterService = OpenRouterService();

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // User message
    _messages.add(
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );
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

      int addedCount = 0;
      int transferCount = 0;

      if (data.containsKey('parsedCommandModels')) {
        final List<dynamic> models = data['parsedCommandModels'];
        for (var item in models) {
          String category = item['category'] ?? 'Others';
          double amount = (item['amount'] is num)
              ? (item['amount'] as num).toDouble()
              : double.tryParse(item['amount'].toString()) ?? 0.0;
          String type = item['type'] ?? 'Expense';
          String remark = item['remark'] ?? '';

          bool isExpense = type.toLowerCase() != 'income';

          final tx = TransactionModel(
            id:
                DateTime.now().microsecondsSinceEpoch.toString() +
                addedCount.toString(),
            amount: amount,
            category: category,
            note: remark,
            timestamp: DateTime.now(),
            createdBy: 'AI',
            accountId: 'default',
            isExpense: isExpense,
          );

          HiveService.transactionsBox.put(tx.id, tx);
          addedCount++;
        }
      }

      if (data.containsKey('transfers')) {
        final List<dynamic> transfers = data['transfers'];
        for (var item in transfers) {
          String fromAccount = item['fromAccount'] ?? '';
          String toAccount = item['toAccount'] ?? '';
          double amount = (item['amount'] is num)
              ? (item['amount'] as num).toDouble()
              : double.tryParse(item['amount'].toString()) ?? 0.0;

          if (fromAccount.isNotEmpty && toAccount.isNotEmpty && amount > 0) {
            final now = DateTime.now();
            final outTx = TransactionModel(
              id: '${now.microsecondsSinceEpoch}out',
              amount: amount,
              category: 'Transfer',
              note: 'Transfer to $toAccount',
              timestamp: now.subtract(const Duration(seconds: 1)),
              createdBy: 'AI',
              accountId: fromAccount,
              isExpense: true,
            );
            final inTx = TransactionModel(
              id: '${now.microsecondsSinceEpoch}in',
              amount: amount,
              category: 'Transfer',
              note: 'Transfer from $fromAccount',
              timestamp: now,
              createdBy: 'AI',
              accountId: toAccount,
              isExpense: false,
            );
            HiveService.transactionsBox.put(outTx.id, outTx);
            HiveService.transactionsBox.put(inTx.id, inTx);
            transferCount++;
          }
        }
      }

      if (addedCount > 0 || transferCount > 0) {
        String advice = data['advice'] ?? '';
        List<String> successMessages = [];
        if (addedCount > 0)
          successMessages.add(
            "✅ Successfully added $addedCount transaction(s).",
          );
        if (transferCount > 0)
          successMessages.add(
            "✅ Successfully executed $transferCount transfer(s).",
          );

        displayText = "${successMessages.join('\n')}\n\n$advice".trim();
      } else if (data.containsKey('advice')) {
        // Empty transactions, just show advice
        displayText = data['advice'] ?? response;
      }
    } catch (e) {
      // Parsing failed or it wasn't JSON, just display the raw text
      displayText = response;
    }

    _messages.add(
      ChatMessage(text: displayText, isUser: false, timestamp: DateTime.now()),
    );
    notifyListeners();
  }
}
