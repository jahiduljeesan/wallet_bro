import 'package:hive/hive.dart';

part 'monthly_summary_model.g.dart';

@HiveType(typeId: 3)
class MonthlySummaryModel extends HiveObject {
  @HiveField(0)
  final String id; // format: "YYYY-MM"

  @HiveField(1)
  final double totalIncome;

  @HiveField(2)
  final double totalExpense;

  @HiveField(3)
  final Map<String, double> categoryBreakdown;

  MonthlySummaryModel({
    required this.id,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'categoryBreakdown': categoryBreakdown,
    };
  }
}
