import 'package:flutter/material.dart';

class HamburgerButton extends StatelessWidget {
  final List<String> selectedViews;
  final List<String> viewOptions;
  final Function(String) onViewSelected;

  const HamburgerButton({
    super.key,
    required this.selectedViews,
    required this.viewOptions,
    required this.onViewSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu, color: Colors.white),
      onSelected: (value) {
        onViewSelected(value);
      },
      itemBuilder: (context) {
        return viewOptions.map((option) {
          bool isSelected = selectedViews.contains(option);
          return PopupMenuItem<String>(
            value: option,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(option, style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.deepPurpleAccent : Colors.black,
                )),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
