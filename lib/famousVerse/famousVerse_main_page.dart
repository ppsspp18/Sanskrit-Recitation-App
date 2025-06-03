// this pages shown only the chapter which are have famous verses

import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/famousVerse/famousVerse_chapter_page.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';


class FamousVerseScreen extends StatefulWidget {
  const FamousVerseScreen({super.key});

  @override
  State<FamousVerseScreen> createState() => _FamousVerseScreenState();
}

class _FamousVerseScreenState extends State<FamousVerseScreen> {
  List<String> chapterIds = [];

  late Color color1;
  late Color color2;
  late Color color3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context);
    color1 = themeProvider.currentTheme.color1;
    color2 = themeProvider.currentTheme.color2;
    color3 = themeProvider.currentTheme.color3;
  }

  @override
  void initState() {
    super.initState();
    _loadFamousVerseChapters();
  }

  Future<void> _loadFamousVerseChapters() async {
    final famousChaptersData = [
      "1.1", "2.7", "2.12", "2.13", "2.20", "2.22", "2.40", "2.41", "2.47", "2.62", "2.63", "2.64", "2.65", "2.66", "2.67", "2.68", "2.69", "2.70", "2.71", "2.72",
      "3.3", "3.8", "3.9", "3.13", "3.16", "3.19", "3.21", "3.27", "3.35", "3.36", "3.37", "3.38", "3.39", "3.40", "3.41", "3.42", "3.43",
      "4.3", "4.7", "4.8", "4.9", "4.11", "4.13", "4.18", "4.24", "4.34", "4.35", "4.39", "4.40",
      "5.10", "5.18", "5.22", "5.29",
      "6.5", "6.6", "6.17", "6.19", "6.23", "6.24", "6.25", "6.26", "6.35", "6.40", "6.44", "6.47",
      "7.1", "7.3", "7.7", "7.14", "7.15", "7.16", "7.17", "7.19", "7.23", "7.24", "7.28",
      "8.5", "8.6", "8.7", "8.14", "8.15", "8.22",
      "9.2", "9.13", "9.14", "9.22", "9.23", "9.25", "9.26", "9.27", "9.30", "9.32", "9.34",
      "10.8", "10.9", "10.10", "10.11", "10.20", "10.41", "10.42",
      "11.54", "11.55",
      "12.6", "12.8", "12.13", "12.14", "12.20",
      "14.26", "14.27",
      "15.6", "15.15", "15.17", "15.19",
      "16.1", "16.2", "16.3", "16.24",
      "17.28",
      "18.5", "18.46", "18.54", "18.55", "18.58", "18.61", "18.62", "18.64", "18.65", "18.66", "18.68", "18.69", "18.78"
    ];
    final famousChapters = famousChaptersData
        .map((entry) => entry.split('.').first)
        .toSet()
        .toList();

    famousChapters.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    setState(() {
      chapterIds = famousChapters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return homePage(context);
  }

  Scaffold homePage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '108 Famous Verses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
            color: color2,
          ),
        ),
        backgroundColor: color1,
        foregroundColor: color2,
        elevation: 6,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: GridView.builder(
          itemCount: chapterIds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // More rows
            crossAxisSpacing: 1, // More space between
            mainAxisSpacing: 1, // More space between rows
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final chapterId = chapterIds[index];
            // Example context for each chapter
            final chapterTitles = [
              "Arjuna's Dilemma",
              "Transcendental Knowledge",
              "Path of Action",
              "Path of Knowledge",
              "Renunciation",
              "Self-Control",
              "Knowledge & Wisdom",
              "Imperishable Brahman",
              "Royal Knowledge",
              "Divine Manifestation",
              "Vision of the Universal Form",
              "Devotion",
              "Field & Knower",
              "Three Gunas",
              "Supreme Person",
              "Divine & Demonic Natures",
              "Threefold Faith",
              "Liberation"
            ];
            final chapterTitle = chapterTitles.length > index ? chapterTitles[index] : "Chapter $chapterId";
            return Card(

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: color3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Aligns text to the top
                  crossAxisAlignment: CrossAxisAlignment.center, // Aligns text to the left
                  children: [
                    Text(
                      'Chapter $chapterId',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapterTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color1,
                            foregroundColor: color2,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(fontSize: 11),
                            minimumSize: const Size(0, 30),
                          ),
                          icon: Icon(Icons.menu_book, size: 16, color: color2,),
                          label: const Text('Read'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FamousVerseChapterPage(chapterId: chapterId)),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color1,
                            foregroundColor: color2,
                            side: BorderSide(color: color1),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(fontSize: 11),
                            minimumSize: const Size(0, 30),
                          ),
                          icon:  Icon(Icons.lightbulb, size: 16, color: color2,),
                          label: const Text('Learn'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Learn mode for Chapter $chapterId coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
