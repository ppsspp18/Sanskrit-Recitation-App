import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';

class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeIndex = themeProvider.selectedThemeIndex;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Theme',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: themeProvider.availableThemes.length,
                itemBuilder: (context, index) {
                  final theme = themeProvider.availableThemes[index];
                  final isSelected = index == currentThemeIndex;
                  
                  return ListTile(
                    leading: Icon(
                      theme.icon,
                      color: theme.theme.colorScheme.primary,
                    ),
                    title: Text(theme.name),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      themeProvider.setTheme(index);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      ),
    );
  }
}

// A simple button to show the theme selection dialog
class ThemeSelectorButton extends StatelessWidget {
  final Widget? label;
  final IconData? icon;
  
  const ThemeSelectorButton({
    Key? key, 
    this.label, 
    this.icon = Icons.color_lens,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return icon != null && label != null
        ? TextButton.icon(
            icon: Icon(icon),
            label: label!,
            onPressed: () => _showThemeSelector(context),
          )
        : icon != null
            ? IconButton(
                icon: Icon(icon),
                onPressed: () => _showThemeSelector(context),
                tooltip: 'Change theme',
              )
            : TextButton(
                onPressed: () => _showThemeSelector(context),
                child: label ?? const Text('Change Theme'),
              );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemeSelectorDialog(),
    );
  }
}
