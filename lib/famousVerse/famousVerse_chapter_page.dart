import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_detail_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_repository.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';

class FamousVerseChapterPage extends StatefulWidget {
  final String chapterId;
  const FamousVerseChapterPage({super.key, required this.chapterId});

  @override
  State<FamousVerseChapterPage> createState() => _FamousVerseChapterPageState();
}

class _FamousVerseChapterPageState extends State<FamousVerseChapterPage> {
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

      final famousmarked = [
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

      // Format for current chapter: "chapter:shloka" => e.g., "2.20"
      final currentChapter = widget.chapterId;
      final famousShlokas = famousmarked
          .where((id) => id.startsWith('$currentChapter.'))
          .map((id) => id.split('.')[1]) // get shloka part
          .toSet();

      final filteredVerses = loadedVerses.where((verse) {
        return famousShlokas.contains(verse.shloka.toString());
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  // Audio indicator if verse has audio
                  if (verse.audioPath?.isNotEmpty == true)
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
            ],
          ),
        ),
      ),
    );
  }
}