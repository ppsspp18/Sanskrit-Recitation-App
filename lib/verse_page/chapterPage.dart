import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanskrit_racitatiion_project/setting_screen/settings_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_detail_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';

class ChapterPage extends StatefulWidget {
  final String chapterId;
  const ChapterPage({super.key, required this.chapterId});

  @override
  State<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  List<Verse> verses = [];

  @override
  void initState() {
    super.initState();
    loadChapterVerses();
  }

  Future<void> loadChapterVerses() async {
    // final stopwatch = Stopwatch()..start();
    // print("Loading JSON...");

    String jsonString = await rootBundle.loadString('assets/verses_template.json');
    // print("JSON loaded in ${stopwatch.elapsed}");
    final decodedData = json.decode(jsonString);
    final List<dynamic> jsonData = decodedData['verses'];
    // print("JSON decoded in ${stopwatch.elapsed}");

    List<Verse> loadedVerses = jsonData.map((e) => Verse.fromJson(e)).toList();
    // print("Verses parsed in ${stopwatch.elapsed}");

    List<Verse> filteredVerses = loadedVerses
        .where((v) => v.id1.toString() == widget.chapterId)
        .toList();

    setState(() {
      verses = filteredVerses;
    });

    // print("Verses for chapter ${widget.chapterId} ready in ${stopwatch.elapsed}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CHAPTER ${widget.chapterId}'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: verses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: verses.length,
        itemBuilder: (context, index) {
          final verse = verses[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text("Verse ${verse.id2}"),
              subtitle: Text(
                verse.textSanskrit1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GitaVersePage(verse: verse),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

