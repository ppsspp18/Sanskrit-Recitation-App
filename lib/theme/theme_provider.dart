import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanskrit_racitatiion_project/theme/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  // Default to the Saffron theme (index 0)
  int _selectedThemeIndex = 0;
  static const String THEME_KEY = "app_theme_index";

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Getter for the current theme
  int get selectedThemeIndex => _selectedThemeIndex;
  
  // Getter for the current ThemeData
  ThemeData get currentTheme => AppThemes.availableThemes[_selectedThemeIndex].theme;

  // Get the list of all available themes
  List<AppTheme> get availableThemes => AppThemes.availableThemes;

  // Change theme by index
  Future<void> setTheme(int index) async {
    if (index >= 0 && index < AppThemes.availableThemes.length) {
      _selectedThemeIndex = index;
      notifyListeners();
      _saveThemeToPrefs(index);
    }
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedThemeIndex = prefs.getInt(THEME_KEY);
    
    if (storedThemeIndex != null && 
        storedThemeIndex >= 0 && 
        storedThemeIndex < AppThemes.availableThemes.length) {
      _selectedThemeIndex = storedThemeIndex;
      notifyListeners();
    }
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(THEME_KEY, index);
  }
}
