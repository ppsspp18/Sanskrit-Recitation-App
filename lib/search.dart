import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _verses = [];
  List<dynamic> _results = [];

  @override
  void initState() {
    super.initState();
    _loadJsonData();
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
  void _search(String query) {
    final normQuery = normalize(query);

    setState(() {
      _results = _verses.where((verse) {
        final combinedText = (verse['sanskrit'] +
            verse['english'] +
            verse['translation'] +
            verse['purport']);
        final normText = normalize(combinedText);
        return normText.contains(normQuery);
      }).toList();
    });
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Search'),
          backgroundColor: const Color(0xFF2C2C54),
          foregroundColor: const Color(0xFFFF9933),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search verse, translation, or purport',
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
                return ListTile(
                  title: Text("Chapter ${item['chapter']} - Shloka ${item['shloka']}", style: TextStyle(color: Color(0xFF2C2C54), fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Verse: ", style: TextStyle(color: Color(0xFF2C2C54), fontWeight: FontWeight.bold)),
                      highlightText(item['english'], _searchController.text),
                      const SizedBox(height: 4),
                      Text("Translation:",style: TextStyle(color: Color(0xFF2C2C54), fontWeight: FontWeight.bold)),
                      highlightText(item['translation'], _searchController.text),
                      const SizedBox(height: 4),
                      Text("Purport:", style: TextStyle(color: Color(0xFF2C2C54), fontWeight: FontWeight.bold)),
                      highlightText(item['purport'], _searchController.text),
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
