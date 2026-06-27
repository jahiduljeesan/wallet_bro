import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isExpense;

  @HiveField(3)
  final String? iconPath; // For PNG/JPG assets (e.g., assets/images/categories/food.png) or local files

  @HiveField(4)
  final int? iconCodePoint; // For Material Icons

  @HiveField(5)
  final String? iconFontFamily; // For Material Icons

  @HiveField(6)
  final bool isCustom;

  CategoryModel({
    required this.id,
    required this.name,
    required this.isExpense,
    this.iconPath,
    this.iconCodePoint,
    this.iconFontFamily,
    this.isCustom = false,
  });
}
