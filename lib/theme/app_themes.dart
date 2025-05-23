import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final ThemeData theme;
  final IconData icon;

  AppTheme({required this.name, required this.theme, required this.icon});
}

class AppThemes {
  // Primary theme colors
  static const Color saffronColor = Color(0xFFFF7F00);
  static const Color deepPurpleColor = Color(0xFF673AB7);
  static const Color tealColor = Color(0xFF009688);
  static const Color blueColor = Color(0xFF2196F3);
  static const Color goldColor = Color(0xFFFFD700);

  // Define available themes
  static final List<AppTheme> availableThemes = [
    AppTheme(
      name: "Saffron (Default)",
      theme: _createSaffronTheme(),
      icon: Icons.format_color_fill,
    ),
    AppTheme(
      name: "Dark Theme",
      theme: _createDarkTheme(),
      icon: Icons.dark_mode,
    ),
    AppTheme(
      name: "Light Theme",
      theme: _createLightTheme(),
      icon: Icons.light_mode,
    ),
    AppTheme(
      name: "Purple Theme",
      theme: _createPurpleTheme(),
      icon: Icons.color_lens,
    ),
    AppTheme(
      name: "Ocean Theme",
      theme: _createTealTheme(),
      icon: Icons.water,
    ),
  ];

  // Saffron Theme - default spiritual theme
  static ThemeData _createSaffronTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: saffronColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: saffronColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: saffronColor,
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData _createDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Light Theme
  static ThemeData _createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Purple Theme
  static ThemeData _createPurpleTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepPurpleColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepPurpleColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Teal Theme
  static ThemeData _createTealTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tealColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
