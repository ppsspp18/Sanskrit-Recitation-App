import 'dart:convert';
import 'package:flutter/services.dart';
import 'verses_model.dart';

/// A repository class to handle loading and processing verse data 
/// including merging verse content with audio mappings
class VerseRepository {
  // Singleton instance
  static final VerseRepository _instance = VerseRepository._internal();
  factory VerseRepository() => _instance;
  VerseRepository._internal();

  // Cached data
  List<Verse_1>? _allVerses;
  Map<String, List<String>>? _audioMappings;

  /// Loads all verses with their audio mappings
  Future<List<Verse_1>> getAllVerses() async {
    if (_allVerses != null) {
      return _allVerses!;
    }
    
    // Load verses from gita.json
    final String gitaJsonString = await rootBundle.loadString('assets/gita.json');
    final List<dynamic> gitaVerses = json.decode(gitaJsonString);
    
    // Load audio mappings
    final audioMappings = await _getAudioMappings();
    
    // Create verse objects and merge with audio mappings
    _allVerses = gitaVerses.map((verseJson) {
      final verse = Verse_1.fromJson(verseJson);
      final audioPaths = audioMappings[verse.verseId] ?? [];
      
      // Create a new verse with the audio paths included
      return Verse_1(
        chapter: verse.chapter,
        shloka: verse.shloka,
        sanskrit: verse.sanskrit,
        english: verse.english,
        synonyms: verse.synonyms,
        translation: verse.translation,
        purport: verse.purport,
        audioPaths: audioPaths,
        verseId: verse.verseId,
      );
    }).toList();
    
    return _allVerses!;
  }

  /// Get verses for a specific chapter
  Future<List<Verse_1>> getVersesForChapter(String chapterId) async {
    final allVerses = await getAllVerses();
    return allVerses.where((verse) => verse.chapter == chapterId).toList();
  }

  /// Get a specific verse by chapter and shloka
  Future<Verse_1?> getVerse(String chapter, String shloka) async {
    final allVerses = await getAllVerses();
    final verseId = "${chapter.padLeft(2, '0')}-${shloka.padLeft(2, '0')}";
    
    try {
      return allVerses.firstWhere((verse) => verse.verseId == verseId);
    } catch (e) {
      return null;
    }
  }

  /// Load audio mappings from audio_mappings.json
  Future<Map<String, List<String>>> _getAudioMappings() async {
    if (_audioMappings != null) {
      return _audioMappings!;
    }
    
    final String mappingJsonString = await rootBundle.loadString('assets/audio_mappings.json');
    final Map<String, dynamic> mappingData = json.decode(mappingJsonString);
    final List<dynamic> mappings = mappingData['mappings'];
    
    _audioMappings = {};
    for (var mapping in mappings) {
      final String verseId = mapping['verseId'];
      final List<String> audioPaths = List<String>.from(mapping['audioPaths']);
      _audioMappings![verseId] = audioPaths;
    }
    
    return _audioMappings!;
  }
}