import 'package:hive/hive.dart';

part 'debt_payment_model.g.dart';

@HiveType(typeId: 6)
class DebtPaymentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String note;

  @HiveField(4, defaultValue: 'cash_account')
  final String accountId;

  DebtPaymentModel({
    required this.id,
    required this.amount,
    required this.timestamp,
    this.note = '',
    this.accountId = 'cash_account',
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'] ?? '',
      accountId: json['accountId'] ?? 'cash_account',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'accountId': accountId,
    };
  }
}
