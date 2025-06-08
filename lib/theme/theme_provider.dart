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
    ThemeColors(Color(0xFF5E35B1), Color(0xFFFF7E67), Color(0xFFEDE7F6), Color(0xFFFFFFFF)), // Deep Violet & Coral
    ThemeColors(Color(0xFF00897B), Color(0xFFEA8D8D), Color(0xFFE0F2F1), Color(0xFFFFFFFF)), // Teal & Rose Gold
    ThemeColors(Color(0xFF1A237E), Color(0xFFFFC107), Color(0xFFE8EAF6), Color(0xFFFFFFFF)), // Midnight Blue & Amber
    ThemeColors(Color(0xFF2E7D32), Color(0xFFFFAB91), Color(0xFFE8F5E9), Color(0xFFFFFFFF)), // Forest Green & Peach
    ThemeColors(Color(0xFF880E4F), Color(0xFFFFD54F), Color(0xFFFCE4EC), Color(0xFFFFFFFF)), // Burgundy & Gold
    ThemeColors(Color(0xFF455A64), Color(0xFF4DD0E1), Color(0xFFECEFF1), Color(0xFFFFFFFF)), // Slate & Aqua
    ThemeColors(Color(0xFF4A148C), Color(0xFF00BCD4), Color(0xFFF3E5F5), Color(0xFFFFFFFF)), // Dark Purple & Turquoise
    ThemeColors(Color(0xFF5D4037), Color(0xFF80CBC4), Color(0xFFFFFDE7), Color(0xFFFFFFFF)), // Chocolate & Mint
    ThemeColors(Color(0xFF263238), Color(0xFFFF8A65), Color(0xFFF5F5F5), Color(0xFFFFFFFF)), // Charcoal & Coral
    ThemeColors(Color(0xFF0D47A1), Color(0xFFFFA000), Color(0xFFBBDEFB), Color(0xFFFFFFFF)), // Navy & Marigold

  ];

  // Initialize _currentTheme to the first available theme
  late ThemeColors _currentTheme = _availableThemes[0];
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

  void setCustomTheme(Color c1, Color c2, Color c3, Color c4) async {
    _currentTheme = ThemeColors(c1, c2, c3, c4);
    _currentIndex = -1; // Indicate custom theme
    notifyListeners();

    // Optionally save custom colors to SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeKey, -1);
    prefs.setInt('customColor1', c1.value);
    prefs.setInt('customColor2', c2.value);
    prefs.setInt('customColor3', c3.value);
    prefs.setInt('customColor4', c4.value);
  }


  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_themeKey) ?? 0;

    if (savedIndex == -1) {
      // Load custom theme
      final c1 = Color(prefs.getInt('customColor1') ?? Colors.blue.value);
      final c2 = Color(prefs.getInt('customColor2') ?? Colors.orange.value);
      final c3 = Color(prefs.getInt('customColor3') ?? Colors.yellow.value);
      final c4 = Color(prefs.getInt('customColor4') ?? Colors.white.value);
      _currentTheme = ThemeColors(c1, c2, c3, c4);
    } else {
      _currentTheme = _availableThemes[savedIndex];
    }
    _currentIndex = savedIndex;
    notifyListeners();
  }


  Future<void> _saveThemeToPrefs(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, index);
  }
}



