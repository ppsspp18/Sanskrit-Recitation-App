import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,

      ),
      body: Column(
        children: [
          AppBar(
            title: Text('Language'),
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          AppBar(
            title: Text('Audio Feature'),
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          )
        ],
      ),
    );
  }
}
