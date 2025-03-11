import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';

class VerseDetailScreen extends StatelessWidget {
  final Verse verse;

  const VerseDetailScreen({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verse ${verse.id}"),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            verse.textTranslation,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
