import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/setting_screen/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BHAGAVAD GITA'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()),);
          }, icon: Icon(Icons.settings))
        ],
        automaticallyImplyLeading: false,
      ),
    );
  }
}
