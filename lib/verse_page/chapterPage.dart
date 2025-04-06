import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanskrit_racitatiion_project/setting_screen/settings_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_detail_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';

class ChapterPage extends StatefulWidget {
  const ChapterPage({super.key});

  @override
  State<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  List<Verse> verses = [];

  @override
  void initState() {
    super.initState();
    loadVerses();
  }

  Future<void> loadVerses() async {
    try {
      String jsonString = await rootBundle.loadString('assets/verses_template.json');
      debugPrint("JSON Loaded: $jsonString");

      List<Verse> loadedVerses = Verse.fromJsonList(jsonString);
      debugPrint("Parsed Verses: ${loadedVerses.length}");

      setState(() {
        verses = loadedVerses;
      });
    } catch (e) {
      debugPrint("Error loading verses: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHAPTER 15'),
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
          )
        ],
        //automaticallyImplyLeading: false,
      ),
      body: verses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: verses.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text("Verse ${verses[index].id}"),
              subtitle: Text(
                verses[index].textSanskrit1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GitaVersePage(verse: verses[index]),
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