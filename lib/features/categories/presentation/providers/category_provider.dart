import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/services/hive_service.dart';
import '../../domain/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => _categories;

  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => !c.isExpense).toList();

  CategoryProvider() {
    _loadCategories();
    HiveService.categoriesBox.listenable().addListener(() {
      _loadCategories();
    });
  }

  void _loadCategories() {
    _categories = HiveService.categoriesBox.values.toList();
    notifyListeners();
  }

  Future<void> addCustomCategory(
    String name,
    bool isExpense, {
    String? pickedImagePath,
    int? iconCodePoint,
  }) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    String? storedImagePath;

    // If an image was picked from the gallery, copy it to the app documents directory
    if (pickedImagePath != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '$id${p.extension(pickedImagePath)}';
        final savedFile = await File(pickedImagePath).copy(p.join(appDir.path, fileName));
        storedImagePath = savedFile.path;
      } catch (e) {
        debugPrint('Error saving custom category image: $e');
      }
    }

    final category = CategoryModel(
      id: id,
      name: name,
      isExpense: isExpense,
      iconPath: storedImagePath,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconCodePoint != null ? 'MaterialIcons' : null,
      isCustom: true,
    );

    await HiveService.categoriesBox.put(id, category);
  }

  Future<void> deleteCategory(String id) async {
    final category = HiveService.categoriesBox.get(id);
    if (category != null && category.isCustom) {
      // If there's a custom image file, we should try to delete it to free space
      if (category.iconPath != null && !category.iconPath!.startsWith('assets/')) {
        try {
          final file = File(category.iconPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting category image file: $e');
        }
      }
      await HiveService.categoriesBox.delete(id);
    }
  }
}
