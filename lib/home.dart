import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/setting_screen/settings_screen.dart';
import 'package:sanskrit_racitatiion_project/chapter_page.dart';
import 'package:sanskrit_racitatiion_project/search.dart';
import 'package:sanskrit_racitatiion_project/bookmark_screen/book_mark.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> chapterIds = List.generate(18, (index) => (index + 1).toString());


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final color1 = themeProvider.currentTheme.color1;
    final color2 = themeProvider.currentTheme.color2;
    final color3 = themeProvider.currentTheme.color3;
    return homePage(context, color1, color2, color3);
  }

  Scaffold homePage(BuildContext context, Color color1, Color color2, Color color3) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BHAGAVAD GITA',
          style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: Icon(Icons.search, color: color2), // Search icon
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  BookmarkScreen()),
              );
            },
            icon: Icon(Icons.bookmark, color: color2), // Bookmark icon
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: Icon(Icons.settings, color: color2), // Settings icon
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: GridView.builder(
          itemCount: chapterIds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // More columns
            crossAxisSpacing: 12, // More space between columns
            mainAxisSpacing: 12, // More space between rows
            childAspectRatio: 0.8, // Adjusted aspect ratio for better fit

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

                  fontSize: 18, // Increased from 15 to 18
                  color: color1,

                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  chapterTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                  fontSize: 14, // Increased from 12 to 14
                  fontWeight: FontWeight.w500,
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
                    textStyle: const TextStyle(fontSize: 13), // Increased from 11 to 13
                    minimumSize: const Size(0, 30),
                    ),
                    icon: Icon(Icons.menu_book, size: 16, color: color2),
                    label: const Text('Read'),
                    onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChapterPage(chapterId: chapterId)),
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
                    textStyle: const TextStyle(fontSize: 13), // Increased from 11 to 13
                    minimumSize: const Size(0, 30),
                    ),
                    icon: Icon(Icons.lightbulb, size: 16, color: color2),
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


