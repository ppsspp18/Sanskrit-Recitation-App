import 'dart:convert';
import 'dart:io';

void main() async {
  print('Starting word meanings generation...');
  
  // Load all verses from gita.json
  final file = File('assets/gita.json');
  if (!await file.exists()) {
    print('❌ assets/gita.json not found. Make sure to run this from the project root directory.');
    return;
  }
  
  final String gitaJsonString = await file.readAsString();
  final List<dynamic> gitaVerses = json.decode(gitaJsonString);
  
  print('Found ${gitaVerses.length} verses to process');
  
  // Process each verse
  final Map<String, Map<String, List<Map<String, dynamic>>>> allProcessedMeanings = {};
  
  for (int i = 0; i < gitaVerses.length; i++) {
    final verse = gitaVerses[i];
    final verseKey = '${verse['chapter']}.${verse['shloka']}';
    
    if ((i + 1) % 50 == 0) {
      print('Processing verse $verseKey (${i + 1}/${gitaVerses.length})');
    }
    
    // Initialize verse data
    allProcessedMeanings[verseKey] = {};
    
    // Create synonym map for processing
    final synonymMap = <String, String>{};
    if (verse['synonyms'] != null) {
      for (var entry in verse['synonyms'].entries) {
        if (entry.value['meaning'] != null) {
          synonymMap[entry.key.toLowerCase()] = entry.value['meaning'];
        }
      }
    }
    
    // Process each line of the verse
    if (verse['english'] != null) {
      final lines = verse['english'].split('\n');
      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        
        final processedWords = processLineWords(line, synonymMap);
        allProcessedMeanings[verseKey]![line] = processedWords;
      }
    }
  }
  
  // Generate statistics
  generateStatistics(allProcessedMeanings);
  
  // Save to assets folder
  try {
    final outputFile = File('assets/processed_word_meanings.json');
    await outputFile.writeAsString(json.encode(allProcessedMeanings));
    print('💾 Saved to assets/processed_word_meanings.json');
  } catch (e) {
    print('⚠️ Error saving file: $e');
  }
  
  print('✅ Word meanings generation completed!');
  print('📁 Generated meanings for ${allProcessedMeanings.length} verses');
}

List<Map<String, dynamic>> processLineWords(String line, Map<String, String> synonymMap) {
  final rawWords = line.split(RegExp(r'\s+'));
  final List<Map<String, dynamic>> processedWords = [];
  
  for (String rawWord in rawWords) {
    if (rawWord.trim().isEmpty) continue;
    
    // Clean the word of punctuation for meaning lookup
    String cleanWord = rawWord.replaceAll(RegExp(r'[^\w\-]'), '');
    
    // Try to find meaning
    String? meaning = findWordMeaning(cleanWord, synonymMap);
    
    processedWords.add({
      'word': rawWord,
      'meaning': meaning,
      'cleanWord': cleanWord,
      'hasCustomMeaning': false,
    });
  }
  
  return processedWords;
}

String? findWordMeaning(String cleanWord, Map<String, String> synonymMap) {
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
        if (wordsMatch(lowerWord, part)) {
          return entry.value;
        }
      }
    }
    
    // Check if this word matches the synonym key
    if (wordsMatch(lowerWord, synonymKey)) {
      return entry.value;
    }
  }
  
  // Strategy 3: Partial matching for Sanskrit transliterations
  for (var entry in synonymMap.entries) {
    final synonymKey = entry.key.toLowerCase();
    
    if (isPartialMatch(lowerWord, synonymKey)) {
      return entry.value;
    }
  }
  
  return null;
}

bool wordsMatch(String word1, String word2) {
  if (word1 == word2) return true;
  
  // Remove common diacritical variations
  String normalized1 = normalizeSanskrit(word1);
  String normalized2 = normalizeSanskrit(word2);
  
  if (normalized1 == normalized2) return true;
  
  // Check if one is a substring of the other (minimum 3 characters)
  if (word1.length >= 3 && word2.length >= 3) {
    if (word1.contains(word2) || word2.contains(word1)) return true;
  }
  
  return false;
}

bool isPartialMatch(String word1, String word2) {
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

String normalizeSanskrit(String word) {
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

void generateStatistics(Map<String, Map<String, List<Map<String, dynamic>>>> data) {
  int totalVerses = data.length;
  int totalLines = 0;
  int totalWords = 0;
  int wordsWithMeaning = 0;
  int wordsWithoutMeaning = 0;

  for (var verseData in data.values) {
    totalLines += verseData.length;
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
