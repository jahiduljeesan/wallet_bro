import 'package:flutter/material.dart';
import '../../../../core/services/hive_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    final settingsBox = HiveService.settingsBox;
    final isDark = settingsBox.get('is_dark_mode');
    
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final settingsBox = HiveService.settingsBox;
    final currentlyDark = _themeMode == ThemeMode.dark;
    final newDark = !currentlyDark;
    
    _themeMode = newDark ? ThemeMode.dark : ThemeMode.light;
    await settingsBox.put('is_dark_mode', newDark);
    
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    if (mode == ThemeMode.system) {
      await HiveService.settingsBox.delete('is_dark_mode');
    } else {
      await HiveService.settingsBox.put('is_dark_mode', mode == ThemeMode.dark);
    }
    notifyListeners();
  }
}
