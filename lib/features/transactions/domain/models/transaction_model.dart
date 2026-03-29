import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String note;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String createdBy; // 'AI' or 'manual'

  @HiveField(6)
  final String accountId;

  // Add enum for transaction type: income or expense? Let's make it simpler: amount can be positive or negative. Or just an enum.
  // Actually, usually expenses are positive in UI or negative depending on context. Let's add an bool isExpense or type.
  @HiveField(7)
  final bool isExpense;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.timestamp,
    required this.createdBy,
    required this.accountId,
    this.isExpense = true,
  });

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? note,
    DateTime? timestamp,
    String? createdBy,
    String? accountId,
    bool? isExpense,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
      accountId: accountId ?? this.accountId,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      note: json['note'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      createdBy: json['createdBy'],
      accountId: json['accountId'],
      isExpense: json['isExpense'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'createdBy': createdBy,
      'accountId': accountId,
      'isExpense': isExpense,
    };
  }
}
