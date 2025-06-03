import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themes = themeProvider.availableThemes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: themeProvider.currentTheme.color1,
        foregroundColor: themeProvider.currentTheme.color2,
      ),
      body: ListView.builder(
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          return ListTile(
            leading: CircleAvatar(backgroundColor: theme.color1),
            title: Text('Theme ${index + 1}'),
            trailing: ElevatedButton(
              onPressed: () {
                themeProvider.changeTheme(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.color1,
                foregroundColor: theme.color2,
              ),
              child: const Text("Select"),
            ),
          );
        },
      ),
    );
  }
}
