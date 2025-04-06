import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/setting_screen/settings_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/chapterPage.dart';

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
        title: const Text('BHAGAVAD GITA'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChapterPage()),
                );
              },
              child: const Text('CHAPTER 15'),
            ),
            // Add more buttons here for other pages if needed
            // ElevatedButton(
            //   onPressed: () {},
            //   child: const Text('Another Page'),
            // ),
          ],
        ),
      ),
    );
  }
}
