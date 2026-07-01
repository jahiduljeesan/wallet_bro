import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 4)
class DebtModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String personName;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final bool isDebt; // true = I Owe (Debt), false = Owed to me (Lend)

  @HiveField(4)
  final bool isSettled;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String note;

  DebtModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isDebt,
    this.isSettled = false,
    required this.timestamp,
    this.note = '',
  });

  DebtModel copyWith({
    String? id,
    String? personName,
    double? amount,
    bool? isDebt,
    bool? isSettled,
    DateTime? timestamp,
    String? note,
  }) {
    return DebtModel(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      isDebt: isDebt ?? this.isDebt,
      isSettled: isSettled ?? this.isSettled,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'],
      personName: json['personName'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isDebt: json['isDebt'] ?? true,
      isSettled: json['isSettled'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'isDebt': isDebt,
      'isSettled': isSettled,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }
}
