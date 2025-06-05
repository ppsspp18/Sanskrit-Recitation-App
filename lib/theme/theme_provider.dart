import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeColors {
  final Color color1;
  final Color color2;
  final Color color3;
  final Color color4;

  ThemeColors(this.color1, this.color2, this.color3, this.color4);
}

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selectedThemeIndex';

  static final List<ThemeColors> _availableThemes = [
    ThemeColors(Color(0xFF2C2C54), Color(0xFFFF9933), Color(0xFFFFE0B2), Color(0xFFFFFFFF)),// indigo and saffron
    ThemeColors(Color(0xFF2E7D32), Color(0xFFFFC107), Color(0xFFF9E79F), Color(0xFFFFFFFF)),// green and gold
    ThemeColors(Color(0xFF006D77), Color(0xFFFFB300), Color(0xFFF9E79F), Color(0xFFFFFFFF)),// teal and yellow
    ThemeColors(Color(0xFFC2185B), Color(0xFF4A0000), Color(0xFFFFE4E1), Color(0xFFFFFFFF)),// pink and maroon
    ThemeColors(Color(0xFF1A237E), Color(0xFFFFA000), Color(0xFFBBDEFB), Color(0xFFFFFFFF)), // Indigo & Amber
    ThemeColors(Color(0xFF4A148C), Color(0xFFD81B60), Color(0xFFF8BBD0), Color(0xFFFFFFFF)), // Deep Purple & Pink
    ThemeColors(Color(0xFF263238), Color(0xFF00ACC1), Color(0xFFB2EBF2), Color(0xFFFFFFFF)), // Blue Grey & Cyan
    ThemeColors(Color(0xFF1B5E20), Color(0xFFCDDC39), Color(0xFFF0F4C3), Color(0xFFFFFFFF)), // Dark Green & Lime
    ThemeColors(Color(0xFF3E2723), Color(0xFFFF7043), Color(0xFFFFCCBC), Color(0xFFFFFFFF)), // Brown & Orange
    ThemeColors(Color(0xFF37474F), Color(0xFF03A9F4), Color(0xFFB3E5FC), Color(0xFFFFFFFF)), // Blue Grey & Light Blue

  ];

  late ThemeColors _currentTheme;
  int _currentIndex = 0;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeColors get currentTheme => _currentTheme;
  List<ThemeColors> get availableThemes => _availableThemes;

  void changeTheme(int index) async {
    if (index >= 0 && index < _availableThemes.length) {
      _currentIndex = index;
      _currentTheme = _availableThemes[index];
      notifyListeners();
      _saveThemeToPrefs(index);
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_themeKey) ?? 0;
    _currentIndex = savedIndex;
    _currentTheme = _availableThemes[_currentIndex];
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, index);
  }
}
