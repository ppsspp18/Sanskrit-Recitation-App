import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeColors {
  final Color color1;
  final Color color2;
  final Color color3;

  ThemeColors(this.color1, this.color2, this.color3);
}

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selectedThemeIndex';

  static final List<ThemeColors> _availableThemes = [
    ThemeColors(Color(0xFF2C2C54), Color(0xFFFF9933), Color(0xFFFFE0B2)),
    ThemeColors(Color(0xFF2E7D32), Color(0xFFFFC107), Color(0xFFF9E79F)),
    ThemeColors(Color(0xFF006D77), Color(0xFFFFB300), Color(0xFFF9E79F)),
    ThemeColors(Color(0xFFC2185B), Color(0xFF4A0000), Color(0xFFFFE4E1)),
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
