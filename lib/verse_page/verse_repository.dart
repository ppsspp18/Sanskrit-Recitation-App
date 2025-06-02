import 'dart:convert';

import 'package:flutter/material.dart';
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
  List<dynamic>? _audioMappings;
  Set<String>? _availableAudioFiles;

  /// Loads all verses with their audio mappings
  Future<List<Verse_1>> getAllVerses() async {
    if (_allVerses != null) {
      return _allVerses!;
    }
    
    // Load verses from gita.json
    final String gitaJsonString = await rootBundle.loadString('gita.json');
    final List<dynamic> gitaVerses = json.decode(gitaJsonString);
    
    // Load audio mappings

    // Get available audio files
    await _loadAvailableAudioFiles();
    
    // Create verse objects and merge with audio mappings
    _allVerses = gitaVerses.map((verseJson) {
      // Create verse from json
      final verse = Verse_1.fromJson(verseJson);
      
      // Find matching audio mapping (if it exists)
      final audioMapping = _findAudioMapping(verse.chapter, verse.shloka);
      
      // Generate audio path using the correct format if chapter and shloka exist
      String? audioPath;
      List<AudioSegment>? segments;
      
      if (verse.chapter.isNotEmpty && verse.shloka.isNotEmpty) {
        // Format the expected audio file path exactly as it appears in the asset folder
        // No need to encode/escape spaces at this stage - we'll handle that properly when creating the AssetSource
        final expectedAudioPath = 'Audio/Bhagavad_gita_${verse.chapter}.${verse.shloka}.mp3';
        
        // Debug log to check the audio path we're looking for
        debugPrint('Looking for audio file: $expectedAudioPath');
        
        // Check if this audio file exists in our known set of files by comparing with normalized paths
        // This handles case sensitivity and slight formatting differences
        final String normalizedPath = expectedAudioPath.toLowerCase().trim();
        final audioExists = _availableAudioFiles?.any((file) => 
          file.toLowerCase().trim() == normalizedPath
        ) ?? false;
        
        if (audioExists) {
          // Get the exact path as it exists in the assets (preserving case)
          final exactPath = _availableAudioFiles?.firstWhere(
            (file) => file.toLowerCase().trim() == normalizedPath,
            orElse: () => expectedAudioPath
          );
          
          audioPath = exactPath;
          debugPrint('Found audio file: $audioPath');
          
          // If we have segments from the audio mapping, use them
          if (audioMapping != null && audioMapping['segments'] != null) {
            segments = (audioMapping['segments'] as List)
                .map((segment) => AudioSegment.fromJson(segment))
                .toList();
          }
        } else {
          debugPrint('Audio file not found for ${verse.chapter}.${verse.shloka}');
        }
      }
      
      // Create a new verse with the audio path and segments included
      return Verse_1(
        chapter: verse.chapter,
        shloka: verse.shloka,
        sanskrit: verse.sanskrit,
        english: verse.english,
        synonyms: verse.synonyms,
        translation: verse.translation,
        purport: verse.purport,
        audioPath: audioPath,
        segments: segments,
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
  Future<List<Verse_1>> getVersesForChapterAndShloka(String chapterId, String shlokaId) async {
    final allVerses = await getAllVerses();
    return allVerses.where((verse) => verse.chapter == chapterId && verse.shloka == shlokaId).toList();
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

  /// Load list of available audio files 
  Future<void> _loadAvailableAudioFiles() async {
    if (_availableAudioFiles != null) {
      return;
    }
    
    _availableAudioFiles = {};
    
    try {
      // Load the asset manifest to check which audio files are actually available
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      debugPrint('Loading audio files from manifest...');
      
      // Filter audio files and add them to our set
      for (var asset in manifestMap.keys) {
        if (asset.contains('/Audio/') && 
            asset.endsWith('.mp3')) {
          // Store without the 'assets/' prefix since AudioPlayers adds it
          final audioPath = asset.replaceFirst('assets/', '');
          _availableAudioFiles!.add(audioPath);
          debugPrint('Found audio file in manifest: $audioPath');
        }
      }
      
      debugPrint('Found ${_availableAudioFiles!.length} audio files available');
      
      // If we didn't find any audio files, probably we're running in dev mode
      // and the manifest doesn't have all entries - try a hardcoded approach
      if (_availableAudioFiles!.isEmpty) {
        _addHardcodedAudioFiles();
      }
    } catch (e) {
      debugPrint('Error loading available audio files: $e');
      // Hard-code some known audio files as a fallback
      _addHardcodedAudioFiles();
    }
  }
  
  /// Add hardcoded audio files if we can't load from manifest
  void _addHardcodedAudioFiles() {
    debugPrint('Using hardcoded audio file paths as fallback');
    
    // Add all the audio files that we know about
    for (var file in _getKnownAudioFiles()) {
      _availableAudioFiles!.add(file);
    }
  }
  
  /// Get a list of all audio files we know are available
  List<String> _getKnownAudioFiles() {
    // This is a list of audio files we know exist in the assets folder
    // Generate paths for all chapters 1-18 and shlokas 1-78 (maximum)
    List<String> files = [];
    for (int chapter = 1; chapter <= 18; chapter++) {
      for (int shloka = 1; shloka <= 78; shloka++) {
        // Format the audio file path
        String filePath = 'Audio/Bhagavad_gita_${chapter.toString().padLeft(2, '0')}.${shloka.toString().padLeft(2, '0')}.mp3';
        files.add(filePath);
      }
    }
    return files;
  }

  /// Load audio mappings from audio_mappings.json

  /// Find audio mapping for a specific chapter and shloka
  Map<String, dynamic>? _findAudioMapping(String chapter, String shloka) {
    if (_audioMappings == null || _audioMappings!.isEmpty) {
      return null;
    }

    try {
      return _audioMappings!.firstWhere(
        (mapping) => mapping['chapter'] == chapter && mapping['shloka'] == shloka,
        orElse: () => {},
      );
    } catch (e) {
      debugPrint('Error finding audio mapping for $chapter.$shloka: $e');
      return null;
    }
  }
}