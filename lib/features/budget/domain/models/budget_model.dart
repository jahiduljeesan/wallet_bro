import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 5)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final bool isMonthly;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.isMonthly = true,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      categoryId: json['categoryId'],
      amount: json['amount'].toDouble(),
      isMonthly: json['isMonthly'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'isMonthly': isMonthly,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? amount,
    bool? isMonthly,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      isMonthly: isMonthly ?? this.isMonthly,
    );
  }
}
