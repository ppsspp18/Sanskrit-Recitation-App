import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sanskrit_racitatiion_project/bookmark_screen/bookmark_manager.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_detail_screen.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_repository.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final VerseRepository _repository = VerseRepository();
  List<Verse_1> verses = [];
  bool _isLoading = true;
  String _filterType = 'All';

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _verses = [];
  List<dynamic> _results = [];
  Set<String> _bookmarkedVerseIds = {};

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
    _loadJsonData();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final ids = await BookmarkManager.getBookmarks();
    setState(() {
      _bookmarkedVerseIds = ids.toSet();
    });
  }

  void _toggleBookmark(String id) async {
    if (_bookmarkedVerseIds.contains(id)) {
      await BookmarkManager.removeBookmark(id);
      setState(() {
        _bookmarkedVerseIds.remove(id);
      });
    } else {
      await BookmarkManager.addBookmark(id);
      setState(() {
        _bookmarkedVerseIds.add(id);
      });
    }
  }


  Future<void> _loadJsonData() async {
    final String jsonString = await rootBundle.loadString('assets/gita.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _verses = jsonData;
    });
  }
  String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[āâàáä]'), 'a')
        .replaceAll(RegExp(r'[īîìíï]'), 'i')
        .replaceAll(RegExp(r'[ūûùúü]'), 'u')
        .replaceAll(RegExp(r'[ṇñń]'), 'n')
        .replaceAll(RegExp(r'[ṭ]'), 't')
        .replaceAll(RegExp(r'[ḍ]'), 'd')
        .replaceAll(RegExp(r'[śṣ]'), 's')
        .replaceAll(RegExp(r'[ēêèéë]'), 'e')
        .replaceAll(RegExp(r'[ōôòóö]'), 'o');
  }

  void _search(String query) async {
    final normQuery = normalize(query);
    final filteredResults = _verses.where((verse) {
      String targetText = '';
      switch (_filterType) {
        case 'Sanskrit':
          targetText = '${verse['chapter']}.${verse['shloka']} ${verse['sanskrit']}';
          break;
        case 'English':
          targetText = '${verse['chapter']}.${verse['shloka']} ${verse['english']}';
          break;
        case 'Translation':
          targetText = '${verse['chapter']}.${verse['shloka']} ${verse['translation']}';
          break;
        case 'Purport':
          targetText = '${verse['chapter']}.${verse['shloka']} ${verse['purport']}';
          break;
        default: // All
          targetText = '${verse['chapter']}.${verse['shloka']} '
              '${verse['sanskrit']} '
              '${verse['english']} '
              '${verse['translation']} '
              '${verse['purport']}';
      }
      return normalize(targetText).contains(normQuery);
    }).toList();

    setState(() {
      _results = filteredResults;
    });

    if (filteredResults.isNotEmpty) {
      final firstChapter = filteredResults.first['chapter'].toString();
      await _loadChapterVersesForNavigation(firstChapter);
    }
  }




  int mapNormalizedIndexToOriginal(String normalized, String original, int normIndex) {
    int origIndex = 0;
    int count = 0;

    while (origIndex < original.length && count < normIndex) {
      String origChar = original[origIndex];
      String normChar = normalize(origChar);
      if (normChar.isNotEmpty) {
        count++;
      }
      origIndex++;
    }

    return origIndex;
  }


  RichText highlightText(String originalText, String query) {
    if (query.isEmpty) {
      return RichText(
        text: TextSpan(text: originalText, style: const TextStyle(color: Colors.black, fontSize: 16)),
      );
    }

    String normalizedQuery = normalize(query);
    String normalizedText = normalize(originalText);

    List<TextSpan> spans = [];
    int currentIndex = 0;

    while (true) {
      int matchIndex = normalizedText.indexOf(normalizedQuery, currentIndex);
      if (matchIndex == -1) {
        spans.add(TextSpan(
            text: originalText.substring(currentIndex),
            style: const TextStyle(color: Colors.black, fontSize: 16)
        )
        );
        break;
      }

      // Map match in normalized text back to original text
      int origMatchStart = mapNormalizedIndexToOriginal(normalizedText, originalText, matchIndex);
      int origMatchEnd = mapNormalizedIndexToOriginal(normalizedText, originalText, matchIndex + normalizedQuery.length);

      if (origMatchStart == -1 || origMatchEnd == -1 || origMatchEnd > originalText.length) {
        spans.add(TextSpan(text: originalText.substring(currentIndex)));
        break;
      }

      if (currentIndex < origMatchStart) {
        spans.add(TextSpan(
            text: originalText.substring(currentIndex, origMatchStart),
            style: const TextStyle(color: Colors.black, fontSize: 16)));
      }

      spans.add(TextSpan(
        text: originalText.substring(origMatchStart, origMatchEnd),
        style: const TextStyle(backgroundColor: Colors.yellow, fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
      ));

      currentIndex = origMatchEnd;
    }

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _loadChapterVersesForNavigation(String chapterId) async {
    try {
      final loadedVerses = await _repository.getVersesForChapter(chapterId);
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
          title: const Text('Search'),
          backgroundColor: color1,
          foregroundColor: color2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text("Search in: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color1)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _filterType,
                  iconEnabledColor: color1,
                  items: [
                    DropdownMenuItem(value: 'All', child: Text('All', style: TextStyle(fontWeight: FontWeight.bold, color: color1))),
                    DropdownMenuItem(value: 'Sanskrit', child: Text('Sanskrit', style: TextStyle(fontWeight: FontWeight.bold, color: color1))),
                    DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(fontWeight: FontWeight.bold, color: color1))),
                    DropdownMenuItem(value: 'Translation', child: Text('Translation', style: TextStyle(fontWeight: FontWeight.bold, color: color1))),
                    DropdownMenuItem(value: 'Purport', child: Text('Purport', style: TextStyle(fontWeight: FontWeight.bold, color: color1))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterType = value!;
                      _search(_searchController.text);
                    });
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: color1, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: color2.withOpacity(0.1),
                hintText: 'Search verse, translation, or purport',
                hintStyle: TextStyle(color: color1),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('No results found.'))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index];
                final chapter = item['chapter'].toString();
                final shloka = item['shloka'].toString();
                final verseId = "$chapter:$shloka";
                final isBookmarked = _bookmarkedVerseIds.contains(verseId);
                final verse = verses.firstWhere(
                      (v) => v.verseId == "$chapter".padLeft(2, '0') + "-" + "$shloka".padLeft(2, '0'),
                  orElse: () => Verse_1.fromJson(item),
                );

                return ListTile(
                  title:
                  Row(
                  children: [
                    ElevatedButton.icon(
                        icon: Icon(Icons.arrow_forward, color: color2),
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GitaVersePage(verses: verses, verse: verse),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color1,
                          foregroundColor: color2,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        ),
                        label: Text("Verse ${item['chapter']}.${item['shloka']}", style: TextStyle(color: color2, fontWeight: FontWeight.bold))
                    ),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? color1 : color1,
                      ),
                      onPressed: () => _toggleBookmark(verseId),
                    ),
                   ]
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_filterType == 'All' || _filterType == 'English') ...[
                        Text("Verse:", style: TextStyle(color: color1, fontWeight: FontWeight.bold)),
                        highlightText(item['english'], _searchController.text),
                        const SizedBox(height: 4),
                      ],
                      if (_filterType == 'All' || _filterType == 'Translation') ...[
                        Text("Translation:", style: TextStyle(color: color1, fontWeight: FontWeight.bold)),
                        highlightText(item['translation'], _searchController.text),
                        const SizedBox(height: 4),
                      ],
                      if (_filterType == 'All' || _filterType == 'Purport') ...[
                        Text("Purport:", style: TextStyle(color: color1, fontWeight: FontWeight.bold)),
                        highlightText(item['purport'], _searchController.text),
                      ],
                    ],
                  ),

                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
