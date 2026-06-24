import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'hive_service.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import '../../features/accounts/domain/models/account_model.dart';

class OpenRouterService {
  final Dio _dio = Dio();

  final String _systemPrompt = '''
You are the built-in AI assistant named "Jemi" inside the Android app "ExpenseBuddy".
        
        Your sole purpose is to help the user manage their personal finance:
        - Track income and expenses
        - Give financial advice or insights
        - Answer budgeting, saving, and spending questions
        
        ---
        
        ### 🧾 Transaction Input Rules
        When the user clearly provides a **new transaction**, respond **only as JSON object** in this format:
        {
          "parsedCommandModels": [
            {"category":"...", "amount":123, "type":"Income|Expense", "remark":"..."}
          ],
          "advice":"..."
        }
        
        or else : 
        
        {
          "parsedCommandModels": [],
          "advice":"..."
        }
        
        Notes:
        - If the user adds multiple transactions in one message, include all in `parsedCommandModels` array.
        - If there are no transactions, return an **empty array** for `parsedCommandModels` and provide **advice** if available.
        - Allowed categories:
          • Expense → Meal, Food, Bills, Rent, Medicine, Education, Travel, Shopping, Beauty, Entertainment, Transportation, Gifts, Subscriptions, Donation, Others  
          • Income → Fixed, Variable, Passive, Bonuses, Refund, Others  
        
        Rules:
        1. Do **not** use categories outside this list.  
        2. If multiple expenses of the **same type** are mentioned, add them together.
        3. “remark” you can improvise to make it short one liner.
        4. “advice” should be a short financial tip based on the entry and overall spending.
        
        ---
        
        ### 📊 Calculation & Insights
        If the user asks for **calculations, summaries, or analysis** (e.g., “What’s my total expense in March 2020?” or "How much money do I have in my Saving account?"), respond **only with a text message**, not JSON.
        
        Example:
        `Total expense of March 2020 is 30000. Tip: You spent 20% more than average.`
        
        You have direct access to the live state of all accounts and transactions below in the system prompt. Use this data to answer calculations, summarize transactions, or detail balance metrics.
        
        ✅ Do **NOT** treat these queries as new transactions.  
        ✅ Do **NOT** return JSON for such queries.
        
        ---
        
        ### 🚫 Non-Financial Topics
        If the user asks about anything unrelated to finance, reply briefly:
        “I can only help with finance-related topics in ExpenseBuddy.”
        but you can greet the user.
        
        If user asks about data and calculation then give them organized details based on the database state.
        
        ---
        
        ### 🧩 Summary of Behavior
        - **Transaction-related input → JSON object** (with `parsedCommandModels` array and optional `advice`)  
        - **Calculation or query → Text answer**  
        - **Non-finance topic → Refusal message**
''';

  Future<String> generateResponse(String prompt) async {
    try {
      final accounts = HiveService.accountsBox.values.toList();
      final transactions = HiveService.transactionsBox.values.toList();

      final Map<String, double> balances = {};
      for (var acc in accounts) {
        balances[acc.id] = acc.initialBalance;
      }
      for (var tx in transactions) {
        if (balances.containsKey(tx.accountId)) {
          if (tx.isExpense) {
            balances[tx.accountId] = balances[tx.accountId]! - tx.amount;
          } else {
            balances[tx.accountId] = balances[tx.accountId]! + tx.amount;
          }
        }
      }

      final StringBuffer dbContext = StringBuffer();
      dbContext.writeln("\n\n### LIVE DATABASE CONTEXT FOR JEMI ###");
      dbContext.writeln("Accounts & Balances:");
      if (accounts.isEmpty) {
        dbContext.writeln("- No accounts registered.");
      } else {
        for (var acc in accounts) {
          final liveBal = balances[acc.id] ?? acc.initialBalance;
          dbContext.writeln("- Account ID: ${acc.id}, Name: ${acc.name}, Type: ${acc.type}, Live Balance: ৳${liveBal.toStringAsFixed(2)}");
        }
      }

      dbContext.writeln("\nRecorded Transactions (sorted newest to oldest):");
      if (transactions.isEmpty) {
        dbContext.writeln("- No transactions recorded.");
      } else {
        final sortedTx = List<TransactionModel>.from(transactions)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        for (var tx in sortedTx) {
          final accName = accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => AccountModel(id: '', name: 'Unknown', type: '')).name;
          dbContext.writeln("- Date: ${tx.timestamp.toIso8601String().substring(0, 10)} ${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}, Account: $accName (ID: ${tx.accountId}), Amount: ৳${tx.amount.toStringAsFixed(2)}, Category: ${tx.category}, Note: ${tx.note}, Type: ${tx.isExpense ? 'Expense' : 'Income'}");
        }
      }

      final fullSystemPrompt = "$_systemPrompt\n${dbContext.toString()}";

      final response = await _dio.post(
        AppConfig.openRouterBaseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
          },
        ),
        data: {
          "model": "nvidia/nemotron-3-super-120b-a12b",
          "messages": [
            {"role": "system", "content": fullSystemPrompt},
            {"role": "user", "content": prompt}
          ],
          "reasoning": {
            "enabled": true
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final String text = data['choices'][0]['message']['content'];
        return text.trim();
      } else {
        return "Error: ${response.statusMessage}";
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg = e.response?.data['error']['message'] ?? 'Unknown Error';
        return "OpenRouter API Error: $errorMsg";
      }
      return "Network Error: Please check your connection.";
    } catch (e) {
      return "Something went wrong. Please try again.";
    }
  }
}
