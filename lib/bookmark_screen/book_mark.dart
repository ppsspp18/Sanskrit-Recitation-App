// this pages shown only the chapter which are bookmarked

import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/bookmark_screen/book_mark_chapter_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<String> chapterIds = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarkedChapters();
  }

  Future<void> _loadBookmarkedChapters() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedVerses = prefs.getStringList('bookmarkedVerses') ?? [];

    // Extract chapter numbers from strings like "2:20"
    final bookmarkedChapters = bookmarkedVerses
        .map((entry) => entry.split(':').first)
        .toSet()
        .toList();

    // Optional: sort numerically
    bookmarkedChapters.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    setState(() {
      chapterIds = bookmarkedChapters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return homePage(context);
  }

  Scaffold homePage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
            color: Color(0xFFFF9933),
          ),
        ),
        backgroundColor: Color(0xFF2C2C54),
        foregroundColor: Color(0xFFFF9933),
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
              color: const Color(0xFFFFE0B2),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Aligns text to the top
                  crossAxisAlignment: CrossAxisAlignment.center, // Aligns text to the left
                  children: [
                    Text(
                      'Chapter $chapterId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF2C2C54),
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
                            backgroundColor: Color(0xFF2C2C54),
                            foregroundColor: Color(0xFFFF9933),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(fontSize: 11),
                            minimumSize: const Size(0, 30),
                          ),
                          icon: const Icon(Icons.menu_book, size: 16),
                          label: const Text('Read'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BookmarkChapterPage(chapterId: chapterId)),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2C2C54),
                            foregroundColor: Color(0xFFFF9933),
                            side: const BorderSide(color: Colors.deepPurpleAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(fontSize: 11),
                            minimumSize: const Size(0, 30),
                          ),
                          icon: const Icon(Icons.lightbulb, size: 16),
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
