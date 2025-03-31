import 'package:flutter/material.dart';

class HamburgerButton extends StatelessWidget {
  final String selectedView;
  final List<String> viewOptions;
  final ValueChanged<String> onViewSelected;

  const HamburgerButton({
    Key? key,
    required this.selectedView,
    required this.viewOptions,
    required this.onViewSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onViewSelected,
      itemBuilder: (context) {
        return viewOptions.map((String option) {
          return PopupMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList();
      },
      icon: Icon(Icons.menu),
    );
  }
}
