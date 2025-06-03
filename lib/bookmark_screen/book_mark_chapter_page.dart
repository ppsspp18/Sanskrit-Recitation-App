import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_detail_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_repository.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanskrit_racitatiion_project/widgets/colors.dart';

class BookmarkChapterPage extends StatefulWidget {
  final String chapterId;
  const BookmarkChapterPage({super.key, required this.chapterId});

  @override
  State<BookmarkChapterPage> createState() => _BookmarkChapterPageState();
}

class _BookmarkChapterPageState extends State<BookmarkChapterPage> {
  final VerseRepository _repository = VerseRepository();
  List<Verse_1> verses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapterVerses();
  }

  Future<void> _loadChapterVerses() async {
    try {
      final loadedVerses = await _repository.getVersesForChapter(widget.chapterId);

      // Load bookmarks
      final prefs = await SharedPreferences.getInstance();
      final bookmarked = prefs.getStringList('bookmarkedVerses') ?? [];

      // Format for current chapter: "chapter:shloka" => e.g., "2:20"
      final currentChapter = widget.chapterId;
      final bookmarkedShlokas = bookmarked
          .where((id) => id.startsWith('$currentChapter:'))
          .map((id) => id.split(':')[1]) // get shloka part
          .toSet();

      final filteredVerses = loadedVerses.where((verse) {
        return bookmarkedShlokas.contains(verse.shloka.toString());
      }).toList();

      setState(() {
        verses = filteredVerses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading verses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CHAPTER ${widget.chapterId}'),
        backgroundColor: color1,
        foregroundColor: color2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildVerseList(),
    );
  }

  Widget _buildVerseList() {
    if (verses.isEmpty) {
      return const Center(
        child: Text(
          'No verses found for this chapter',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        return _buildVerseCard(verse);
      },
    );
  }

  Widget _buildVerseCard(Verse_1 verse) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: color3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GitaVersePage(verses : verses, verse: verse),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Verse ${verse.shloka}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  // Audio indicator if verse has audio
                  if (verse.audioPath?.isNotEmpty == true)
                    const Icon(Icons.audiotrack, color: color1),
                ],
              ),
              const Divider(),
              Text(
                verse.sanskrit,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                verse.translation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}