import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            color: themeProvider.currentTheme.color1,
            child: Text(
              'Change Theme',
              style: TextStyle(
                color: themeProvider.currentTheme.color2,
                fontSize: 20
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: themes.length + 1,
              itemBuilder: (context, index) {
                if (index == themes.length) {
                  return ListTile(
                    leading: Icon(Icons.color_lens, color: Colors.black, size: 50),
                    title: Text(
                      "Custom Theme",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showCustomColorPicker(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        "Choose",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                final theme = themes[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: theme.color1),
                  title: Text(
                    'Theme ${index + 1}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
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
          ),
        ],
      ),
    );
  }
}
void _showCustomColorPicker(BuildContext context) {
  Color color1 = Color(0xFF2C2C54);
  Color color2 = Color(0xFFFF9933);
  Color color3 = Color(0xFFFFE0B2);
  Color color4 = Color(0xFFFFFFFF);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Pick 4 Theme Colors', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            children: [
              const Text('Primary Color', style: TextStyle(fontWeight: FontWeight.bold)),
              ColorPicker(pickerColor: color1, onColorChanged: (c) => color1 = c),
              const Text('Secondary Color', style: TextStyle(fontWeight: FontWeight.bold)),
              ColorPicker(pickerColor: color2, onColorChanged: (c) => color2 = c),
              const Text('Text Background Color', style: TextStyle(fontWeight: FontWeight.bold)),
              ColorPicker(pickerColor: color3, onColorChanged: (c) => color3 = c),
              const Text('Screen Background Color', style: TextStyle(fontWeight: FontWeight.bold)),
              ColorPicker(pickerColor: color4, onColorChanged: (c) => color4 = c),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            Provider.of<ThemeProvider>(context, listen: false)
                .setCustomTheme(color1, color2, color3, color4);
            Navigator.pop(context);
          },
          child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}


