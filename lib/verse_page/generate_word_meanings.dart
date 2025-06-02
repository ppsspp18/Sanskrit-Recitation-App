import 'dart:convert';
import 'dart:io';
// Remove Flutter dependency for standalone execution
// import 'package:flutter/services.dart';
import 'verses_model.dart';
import 'word_meaning_service.dart';

/// Script to pre-process all verses and generate the complete processed_word_meanings.json file
/// This should be run once to create the initial database of word meanings
class WordMeaningsGenerator {
  final WordMeaningService _wordMeaningService = WordMeaningService();

  /// Generate word meanings for all verses and save to JSON
  Future<void> generateAllWordMeanings() async {
    try {
      print('Starting word meanings generation...');
      
      // Load all verses from gita.json (read directly from file for standalone execution)
      final file = File('assets/gita.json');
      if (!await file.exists()) {
        throw Exception('assets/gita.json not found. Make sure to run this from the project root directory.');
      }
      
      final String gitaJsonString = await file.readAsString();
      final List<dynamic> gitaVerses = json.decode(gitaJsonString);
      
      // Convert to Verse_1 objects
      final List<Verse_1> verses = gitaVerses.map((verseJson) => Verse_1.fromJson(verseJson)).toList();
      
      print('Found ${verses.length} verses to process');
      
      // Process each verse
      final Map<String, Map<String, List<Map<String, dynamic>>>> allProcessedMeanings = {};
      
      for (int i = 0; i < verses.length; i++) {
        final verse = verses[i];
        final verseKey = '${verse.chapter}.${verse.shloka}';
        
        print('Processing verse $verseKey (${i + 1}/${verses.length})');
        
        // Process this verse
        await _processVerse(verse, allProcessedMeanings);
        
        // Show progress every 10 verses
        if ((i + 1) % 10 == 0) {
          print('Completed ${i + 1}/${verses.length} verses');
        }
      }
      
      // Generate and display statistics
      generateStatistics(allProcessedMeanings);
      
      // Save to assets folder (for distribution with app)
      await _saveToAssetsFile(allProcessedMeanings);
      
      print('✅ Word meanings generation completed!');
      print('📁 Generated meanings for ${allProcessedMeanings.length} verses');
      print('📊 Total processed lines: ${_countTotalLines(allProcessedMeanings)}');
      
    } catch (e) {
      print('❌ Error generating word meanings: $e');
      rethrow;
    }
  }

  /// Process a single verse and add to the results
  Future<void> _processVerse(Verse_1 verse, Map<String, Map<String, List<Map<String, dynamic>>>> allProcessedMeanings) async {
    final verseKey = '${verse.chapter}.${verse.shloka}';
    
    // Initialize verse data
    allProcessedMeanings[verseKey] = {};
    
    // Create synonym map for processing
    final synonymMap = <String, String>{};
    for (var entry in verse.synonyms.entries) {
      synonymMap[entry.key.toLowerCase()] = entry.value.meaning;
    }
    
    // Process each line of the verse
    final lines = verse.english.split('\n');
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      final processedWords = _processLineWords(line, synonymMap);
      allProcessedMeanings[verseKey]![line] = processedWords;
    }
  }

  /// Process words in a line and return structured data
  List<Map<String, dynamic>> _processLineWords(String line, Map<String, String> synonymMap) {
    final rawWords = line.split(RegExp(r'\s+'));
    final List<Map<String, dynamic>> processedWords = [];
    
    for (String rawWord in rawWords) {
      if (rawWord.trim().isEmpty) continue;
      
      final wordData = _processWordWithMeaning(rawWord, synonymMap);
      processedWords.addAll(wordData);
    }
    
    return processedWords;
  }

  /// Process a single word and find its meaning(s)
  List<Map<String, dynamic>> _processWordWithMeaning(String rawWord, Map<String, String> synonymMap) {
    final List<Map<String, dynamic>> results = [];
    
    // Clean the word of punctuation for meaning lookup
    String cleanWord = rawWord.replaceAll(RegExp(r'[^\w\-]'), '');
    
    // Try different approaches to find meaning
    String? meaning = _findWordMeaning(cleanWord, synonymMap);
    
    if (meaning != null) {
      // Direct match found
      results.add({
        'word': rawWord,
        'meaning': meaning,
        'cleanWord': cleanWord,
        'hasCustomMeaning': false,
      });
    } else {
      // Try to split compound words and find meanings for parts
      final splitResults = _splitAndFindMeanings(rawWord, cleanWord, synonymMap);
      results.addAll(splitResults);
    }
    
    return results;
  }

  /// Find meaning for a word using various matching strategies
  String? _findWordMeaning(String cleanWord, Map<String, String> synonymMap) {
    final lowerWord = cleanWord.toLowerCase();
    
    // Strategy 1: Exact match
    if (synonymMap.containsKey(lowerWord)) {
      return synonymMap[lowerWord];
    }
    
    // Strategy 2: Check if word is part of a compound synonym
    for (var entry in synonymMap.entries) {
      final synonymKey = entry.key.toLowerCase();
      
      // Check if the synonym contains this word as a component
      if (synonymKey.contains('-') || synonymKey.contains(' ')) {
        final parts = synonymKey.split(RegExp(r'[-\s]+'));
        for (String part in parts) {
          if (_wordsMatch(lowerWord, part)) {
            return entry.value;
          }
        }
      }
      
      // Check if this word matches the synonym key
      if (_wordsMatch(lowerWord, synonymKey)) {
        return entry.value;
      }
    }
    
    // Strategy 3: Partial matching for Sanskrit transliterations
    for (var entry in synonymMap.entries) {
      final synonymKey = entry.key.toLowerCase();
      
      if (_isPartialMatch(lowerWord, synonymKey)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Split compound words and find meanings for each part
  List<Map<String, dynamic>> _splitAndFindMeanings(String originalWord, String cleanWord, Map<String, String> synonymMap) {
    final List<Map<String, dynamic>> results = [];
    
    // Try splitting by common Sanskrit compound indicators
    List<String> parts = [];
    
    // Split by hyphens
    if (cleanWord.contains('-')) {
      parts = cleanWord.split('-');
    }
    // Try to identify compound words by looking for matching synonym patterns
    else {
      parts = _intelligentWordSplit(cleanWord, synonymMap);
    }
    
    if (parts.length > 1) {
      // Process each part
      for (int i = 0; i < parts.length; i++) {
        String part = parts[i];
        String? meaning = _findWordMeaning(part, synonymMap);
        
        results.add({
          'word': part,
          'meaning': meaning,
          'cleanWord': part,
          'isPart': true,
          'hasCustomMeaning': false,
        });
      }
    } else {
      // No meaningful split found, return as single word without meaning
      results.add({
        'word': originalWord,
        'meaning': null,
        'cleanWord': cleanWord,
        'hasCustomMeaning': false,
      });
    }
    
    return results;
  }

  /// Intelligent word splitting based on synonym patterns
  List<String> _intelligentWordSplit(String word, Map<String, String> synonymMap) {
    // Look for patterns in synonyms that might help split this word
    for (var synonymKey in synonymMap.keys) {
      final cleanSynonym = synonymKey.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      
      if (word.toLowerCase().contains(cleanSynonym) || cleanSynonym.contains(word.toLowerCase())) {
        // Try to find where this word might split based on the synonym
        if (synonymKey.contains('-')) {
          final synonymParts = synonymKey.split('-');
          return _trySplitBasedOnPattern(word, synonymParts);
        }
      }
    }
    
    // If no pattern found, return the word as is
    return [word];
  }

  /// Try to split a word based on a pattern from synonyms
  List<String> _trySplitBasedOnPattern(String word, List<String> pattern) {
    final List<String> result = [];
    String remaining = word.toLowerCase();
    
    for (String patternPart in pattern) {
      final cleanPattern = patternPart.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      
      if (remaining.startsWith(cleanPattern)) {
        result.add(word.substring(0, cleanPattern.length));
        word = word.substring(cleanPattern.length);
        remaining = remaining.substring(cleanPattern.length);
      } else if (remaining.contains(cleanPattern)) {
        final index = remaining.indexOf(cleanPattern);
        if (index > 0) {
          result.add(word.substring(0, index));
          word = word.substring(index);
          remaining = remaining.substring(index);
        }
        result.add(word.substring(0, cleanPattern.length));
        word = word.substring(cleanPattern.length);
        remaining = remaining.substring(cleanPattern.length);
      }
    }
    
    if (word.isNotEmpty) {
      result.add(word);
    }
    
    return result.isEmpty ? [word] : result;
  }

  /// Check if two words match using various strategies
  bool _wordsMatch(String word1, String word2) {
    if (word1 == word2) return true;
    
    // Remove common diacritical variations
    String normalized1 = _normalizeSanskrit(word1);
    String normalized2 = _normalizeSanskrit(word2);
    
    if (normalized1 == normalized2) return true;
    
    // Check if one is a substring of the other (minimum 3 characters)
    if (word1.length >= 3 && word2.length >= 3) {
      if (word1.contains(word2) || word2.contains(word1)) return true;
    }
    
    // Check prefix matching (70% rule)
    final minLength = (word1.length * 0.7).round();
    if (word1.length >= 3 && word2.length >= 3 && minLength >= 2) {
      if (word1.substring(0, minLength.clamp(0, word1.length)) == 
          word2.substring(0, minLength.clamp(0, word2.length))) {
        return true;
      }
    }
    
    return false;
  }

  /// Check for partial matches
  bool _isPartialMatch(String word1, String word2) {
    if (word1.length < 3 || word2.length < 3) return false;
    
    // Check if words share a significant common substring
    final minLength = [word1.length, word2.length].reduce((a, b) => a < b ? a : b);
    final threshold = (minLength * 0.6).round();
    
    for (int i = 0; i <= word1.length - threshold; i++) {
      String substring = word1.substring(i, i + threshold);
      if (word2.contains(substring)) {
        return true;
      }
    }
    
    return false;
  }

  /// Normalize Sanskrit transliteration
  String _normalizeSanskrit(String word) {
    return word
        .replaceAll('ā', 'a')
        .replaceAll('ī', 'i')
        .replaceAll('ū', 'u')
        .replaceAll('ṛ', 'r')
        .replaceAll('ṝ', 'r')
        .replaceAll('ḷ', 'l')
        .replaceAll('ṃ', 'm')
        .replaceAll('ḥ', 'h')
        .replaceAll('ñ', 'n')
        .replaceAll('ṅ', 'n')
        .replaceAll('ṇ', 'n')
        .replaceAll('ṭ', 't')
        .replaceAll('ḍ', 'd')
        .replaceAll('ś', 's')
        .replaceAll('ṣ', 's');
  }

  /// Save to assets file (for distribution with app)
  Future<void> _saveToAssetsFile(Map<String, Map<String, List<Map<String, dynamic>>>> data) async {
    try {
      final file = File('assets/processed_word_meanings.json');
      await file.writeAsString(json.encode(data));
      print('💾 Saved to assets/processed_word_meanings.json');
    } catch (e) {
      print('⚠️ Error saving to assets file: $e');
    }
  }

  /// Save to local storage (for runtime updates)
  Future<void> _saveToLocalStorage(Map<String, Map<String, List<Map<String, dynamic>>>> data) async {
    try {
      // This will use the WordMeaningService to save to local storage
      await _wordMeaningService.clearCache();
      // The service will automatically load from assets and then we can update it
    } catch (e) {
      print('⚠️ Error saving to local storage: $e');
    }
  }

  /// Count total processed lines for statistics
  int _countTotalLines(Map<String, Map<String, List<Map<String, dynamic>>>> data) {
    int count = 0;
    for (var verseData in data.values) {
      count += verseData.length;
    }
    return count;
  }

  /// Generate statistics about the processed data
  void generateStatistics(Map<String, Map<String, List<Map<String, dynamic>>>> data) {
    int totalVerses = data.length;
    int totalLines = _countTotalLines(data);
    int totalWords = 0;
    int wordsWithMeaning = 0;
    int wordsWithoutMeaning = 0;

    for (var verseData in data.values) {
      for (var lineWords in verseData.values) {
        for (var wordData in lineWords) {
          totalWords++;
          if (wordData['meaning'] != null) {
            wordsWithMeaning++;
          } else {
            wordsWithoutMeaning++;
          }
        }
      }
    }

    print('\n📊 Generation Statistics:');
    print('├── Total Verses: $totalVerses');
    print('├── Total Lines: $totalLines');
    print('├── Total Words: $totalWords');
    print('├── Words with Meaning: $wordsWithMeaning (${(wordsWithMeaning / totalWords * 100).toStringAsFixed(1)}%)');
    print('└── Words without Meaning: $wordsWithoutMeaning (${(wordsWithoutMeaning / totalWords * 100).toStringAsFixed(1)}%)');
  }
}

/// Main function to run the generator
Future<void> main() async {
  final generator = WordMeaningsGenerator();
  await generator.generateAllWordMeanings();
}