import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_detail_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_repository.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';

class ChapterPage extends StatefulWidget {
  final String chapterId;
  const ChapterPage({super.key, required this.chapterId});

  @override
  State<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  final VerseRepository _repository = VerseRepository();
  List<Verse_1> verses = [];
  bool _isLoading = true;

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
    _loadChapterVerses();
  }

  Future<void> _loadChapterVerses() async {
    try {
      final loadedVerses = await _repository.getVersesForChapter(widget.chapterId);
      setState(() {
        verses = loadedVerses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // You might want to add error handling here
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
              builder: (context) => GitaVersePage(verses: verses, verse: verse),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  // Audio indicator if verse has audio
                  if (verse.audioPath != null)
                     Icon(Icons.audiotrack, color: color1),

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
              // Add segment indicator if available
              if (verse.segments != null && verse.segments!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.segment, 
                        size: 16, 
                        color: color1,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${verse.segments!.length} segments available',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}