import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'verses_model.dart';

class WordMeaningService {
  static final WordMeaningService _instance = WordMeaningService._internal();
  factory WordMeaningService() => _instance;
  WordMeaningService._internal();

  // Cache for processed word meanings
  Map<String, Map<String, List<Map<String, dynamic>>>>? _cachedWordMeanings;

  /// Load processed word meanings from JSON file
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> _loadWordMeanings() async {
    if (_cachedWordMeanings != null) {
      return _cachedWordMeanings!;
    }

    try {
      // Try to load from local storage first (user-generated file)
      final String? localData = await _loadFromLocalStorage();
      if (localData != null) {
        _cachedWordMeanings = Map<String, Map<String, List<Map<String, dynamic>>>>.from(
          json.decode(localData).map((key, value) => MapEntry(
            key,
            Map<String, List<Map<String, dynamic>>>.from(
              value.map((k, v) => MapEntry(
                k,
                List<Map<String, dynamic>>.from(v)
              ))
            )
          ))
        );
        return _cachedWordMeanings!;
      }

      // If no local file, try to load from assets
      final String assetData = await rootBundle.loadString('assets/processed_word_meanings.json');
      _cachedWordMeanings = Map<String, Map<String, List<Map<String, dynamic>>>>.from(
        json.decode(assetData).map((key, value) => MapEntry(
          key,
          Map<String, List<Map<String, dynamic>>>.from(
            value.map((k, v) => MapEntry(
              k,
              List<Map<String, dynamic>>.from(v)
            ))
          )
        ))
      );
    } catch (e) {
      debugPrint('Error loading processed meanings: $e');
      // If no file exists, return empty map
      _cachedWordMeanings = {};
    }

    return _cachedWordMeanings!;
  }

  /// Save word meanings to local storage
  Future<void> _saveWordMeanings(Map<String, Map<String, List<Map<String, dynamic>>>> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/processed_word_meanings.json');
      await file.writeAsString(json.encode(data));
      _cachedWordMeanings = data; // Update cache
    } catch (e) {
      debugPrint('Error saving word meanings: $e');
    }
  }

  /// Get processed word meanings for a specific verse
  Future<List<Map<String, dynamic>>?> getVerseWordMeanings(String chapter, String shloka, String line) async {
    final processedMeanings = await _loadWordMeanings();
    final verseKey = '$chapter.$shloka';
    
    if (processedMeanings.containsKey(verseKey) && 
        processedMeanings[verseKey]!.containsKey(line)) {
      return processedMeanings[verseKey]![line]!;
    }

    // If not found, return null (will trigger processing)
    return null;
  }

  /// Process and store word meanings for a verse
  Future<void> processAndStoreVerseMeanings(Verse_1 verse) async {
    final processedMeanings = await _loadWordMeanings();
    final verseKey = '${verse.chapter}.${verse.shloka}';
    
    // Initialize verse data if not exists
    processedMeanings[verseKey] ??= {};
    
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
      processedMeanings[verseKey]![line] = processedWords;
    }
    
    // Save to local storage
    await _saveWordMeanings(processedMeanings);
  }

  /// Add a custom meaning provided by the user
  Future<void> addCustomMeaning(String word, String meaning) async {
    try {
      // Load current data
      final data = await _loadWordMeanings();
      
      // Find all instances of this word across all verses and update them
      bool foundAndUpdated = false;
      
      for (var verseKey in data.keys) {
        final verseData = data[verseKey]!;
        for (var lineKey in verseData.keys) {
          final lineWords = verseData[lineKey]!;
          
          for (int i = 0; i < lineWords.length; i++) {
            final wordData = lineWords[i];
            final cleanWordLower = (wordData['cleanWord'] as String).toLowerCase();
            final inputWordLower = word.toLowerCase().replaceAll(RegExp(r'[^\w\-]'), '');
            
            // Check if this word matches (using the same matching logic as processing)
            if (_wordsMatch(cleanWordLower, inputWordLower)) {
              lineWords[i] = {
                ...wordData,
                'meaning': meaning,
                'hasCustomMeaning': true,
              };
              foundAndUpdated = true;
            }
          }
        }
      }
      
      if (foundAndUpdated) {
        // Save the updated data
        await _saveWordMeanings(data);
        
        debugPrint('✅ Added custom meaning for "$word": "$meaning"');
      } else {
        debugPrint('⚠️ Word "$word" not found in any verse');
        throw Exception('Word "$word" not found in any verse');
      }
    } catch (e) {
      debugPrint('❌ Error adding custom meaning: $e');
      rethrow;
    }
  }

  /// Get custom meanings provided by users
  Future<Map<String, String>> getCustomMeanings() async {
    try {
      final String? customData = await _loadCustomMeaningsFromStorage();
      if (customData != null) {
        return Map<String, String>.from(json.decode(customData));
      }
    } catch (e) {
      debugPrint('Error loading custom meanings: $e');
    }
    return {};
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    _cachedWordMeanings = null;
  }

  /// Get meaning for a word (checks custom meanings first, then processed meanings)
  Future<String?> getWordMeaning(String word) async {
    final customMeanings = await getCustomMeanings();
    final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w\-]'), '');
    
    // Check custom meanings first
    if (customMeanings.containsKey(cleanWord)) {
      return customMeanings[cleanWord];
    }
    
    // Could add more logic here to search through processed meanings
    return null;
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

  /// Load processed meanings from local storage
  Future<String?> _loadFromLocalStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/processed_word_meanings.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
    }
    return null;
  }

  /// Save processed meanings to local storage
  Future<void> _saveToLocalStorage(Map<String, Map<String, List<Map<String, dynamic>>>> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/processed_word_meanings.json');
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  /// Load custom meanings from local storage
  Future<String?> _loadCustomMeaningsFromStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/custom_word_meanings.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Error loading custom meanings: $e');
    }
    return null;
  }

  /// Save custom meanings to local storage
  Future<void> _saveCustomMeaningsToStorage(Map<String, String> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/custom_word_meanings.json');
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving custom meanings: $e');
    }
  }
}