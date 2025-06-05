import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';
import 'package:sanskrit_racitatiion_project/verse_page/word_meaning_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanskrit_racitatiion_project/bookmark_screen/bookmark_manager.dart';
import 'package:sanskrit_racitatiion_project/verse_page/audio_player_widget.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';

class GitaVersePage extends StatefulWidget {
  final List<Verse_1> verses; // List of verses in the chapter
  final Verse_1 verse;// Current index of the verse in the chapter
  final void Function(bool)? onNavigate; // Callback for navigation
  
  const GitaVersePage({
    super.key,
    required this.verses,
    required this.verse,
    this.onNavigate,
  });

  @override
  State<GitaVersePage> createState() => _GitaVersePageState();
}

class _GitaVersePageState extends State<GitaVersePage> {
  // Services
  final WordMeaningService _wordMeaningService = WordMeaningService();
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
  
  // UI Constants for consistent theming
  // Colors
  Color get primaryColor => color1;
  Color get dividerColor => color2;
  static const Color textPrimaryColor = Colors.black;
  static const Color textSecondaryColor = Colors.grey;
  static const Color errorColor = Colors.red;
  
  // Font Sizes
  static const double fontSizeHeading = 18.0;
  static const double fontSizeSubheading = 16.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeCaption = 14.0;
  static const double fontSizeSanskrit = 16.0;
  static const double fontSizeMeaning = 10.0;
  static const double fontSizeSmall = 12.0;

  // Audio player state
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  // Bookmark state
  bool _isBookmarked = false;

  // UI state
  bool _isAdvancedView = false;
  bool _showDevanagari = true;
  bool _showTransliteration = true;
  bool _showSynonyms = false;
  bool _showTranslation = false;
  bool _showPurport = false;

  // Text editing controller for adding custom meanings
  final TextEditingController _meaningController = TextEditingController();
  
  // For tooltip display
  bool _tooltipVisible = false;
  String _tooltipText = '';
  Offset _tooltipPosition = Offset.zero;
  bool _tooltipLocked = false;

  // Custom meanings storage
  Map<String, String> _customMeanings = {};

  late int index;
  late Verse_1 verse;

  @override
  void initState() {
    super.initState();
    _loadCustomMeanings();
    //_checkBookmark();
    _loadBookmarks();
    _loadPreferences();

    index = widget.verses.indexWhere((v) => v.shloka == widget.verse.shloka);
    if (index == -1) index = 0; // fallback in case of no match
    
    // Load word meanings for the verse
    // _loadWordMeanings();
    
    // Set up audio player if audio path is available
    if (widget.verse.audioPath != null) {
      _setupAudioPlayer();
    }
  }

  Future<void> _loadBookmarks() async {
    final ids = await BookmarkManager.getBookmarks();
    setState(() {
      _bookmarkedVerseIds = ids.toSet();
    });
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showDevanagari = prefs.getBool('showDevanagari') ?? true;
      _showTransliteration = prefs.getBool('showTransliteration') ?? true;
      _showSynonyms = prefs.getBool('showSynonyms') ?? true;
      _showTranslation = prefs.getBool('showTranslation') ?? true;
      _showPurport = prefs.getBool('showPurport') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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

  void _setupAudioPlayer() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Log the audio path for debugging
      final audioPath = widget.verse.audioPath!;
      debugPrint('Audio path from verse: $audioPath');
      
      // Set up player event listeners
      _audioPlayer.onDurationChanged.listen((d) {
        setState(() => _duration = d);
        debugPrint('Duration set: ${d.inSeconds} seconds');
      });
      
      _audioPlayer.onPositionChanged.listen((p) => 
        setState(() => _position = p)
      );
      
      _audioPlayer.onPlayerComplete.listen((_) => 
        setState(() {
          isPlaying = false;
          _position = Duration.zero;
        })
      );
      
      // Load audio source
      _loadAudioSource();
      
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      setState(() {
        _errorMessage = 'Error initializing audio player: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadAudioSource() async {
    if (widget.verse.audioPath == null) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final audioPath = widget.verse.audioPath!;
      debugPrint('Loading audio from asset: $audioPath');
      
      // Try different approaches to load the audio file
      bool success = false;
      Exception? lastError;
      
      // Approach 1: Try using AssetSource with original path
      try {
        final source = AssetSource(audioPath);
        await _audioPlayer.setSource(source);
        success = true;
        debugPrint('Successfully loaded audio using AssetSource with original path');
      } catch (e) {
        lastError = e as Exception;
        debugPrint('Error with approach 1: $e');
      }
      
      // Approach 2: If file has spaces, try the 'assets/' prefix path
      if (!success && audioPath.contains(' ')) {
        try {
          debugPrint('Trying with assets/ prefix...');
          final alternateAudioPath = 'assets/$audioPath';
          debugPrint('Alternate path: $alternateAudioPath');
          
          await _audioPlayer.setSourceUrl(alternateAudioPath);
          success = true;
          debugPrint('Successfully loaded audio using assets/ prefix path');
        } catch (e) {
          lastError = e as Exception;
          debugPrint('Error with approach 2: $e');
        }
      }
      
      // Approach 3: Try with a URL-encoded path
      if (!success && audioPath.contains(' ')) {
        try {
          debugPrint('Trying with URL encoded path...');
          final encodedPath = Uri.encodeFull('assets/$audioPath');
          debugPrint('Encoded path: $encodedPath');
          
          await _audioPlayer.setSourceUrl(encodedPath);
          success = true;
          debugPrint('Successfully loaded audio using URL-encoded path');
        } catch (e) {
          lastError = e as Exception;
          debugPrint('Error with approach 3: $e');
        }
      }
      
      // Approach 4: Try with a file:// prefix for local assets
      if (!success) {
        try {
          debugPrint('Trying with file:// prefix...');
          final filePrefix = 'file:///android_asset/flutter_assets/$audioPath';
          debugPrint('File path: $filePrefix');
          
          await _audioPlayer.setSourceUrl(filePrefix);
          success = true;
          debugPrint('Successfully loaded audio using file:// prefix');
        } catch (e) {
          lastError = e as Exception;
          debugPrint('Error with approach 4: $e');
        }
      }
      
      if (success) {
        debugPrint('Audio source set successfully');
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        debugPrint('All approaches failed');
        setState(() {
          _errorMessage = 'Could not load audio file. Please try again later.';
          _isLoading = false;
        });
        
        // Log additional details for debugging
        debugPrint('Audio loading failed for path: $audioPath');
        debugPrint('Last error: $lastError');
      }
    } catch (e) {
      debugPrint('Exception in _loadAudioSource: $e');
      setState(() {
        _errorMessage = 'Could not load audio file: $e';
        _isLoading = false;
      });
    }
  }

  void _playAudio() async {
    if (widget.verse.audioPath == null) return;
    
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        setState(() => _isLoading = true);
        
        // Check if we need to reload the source
        if (_duration == Duration.zero || _errorMessage != null) {
          _errorMessage = null;
          await _loadAudioSource();
        }
        
        await _audioPlayer.resume();
        setState(() {
          isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() {
        _errorMessage = 'Error playing audio: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  void _toggleTooltipLock() {
    setState(() {
      _tooltipLocked = !_tooltipLocked;
    });
  }

  // Toggle advanced view mode
  void _toggleAdvancedView() {
    setState(() {
      _isAdvancedView = !_isAdvancedView;
    });
  }

  // Navigate to previous verse

  void _navigateToPreviousVerse() {
    if(index >0){
      final verse = widget.verses[index-1];
      final verses = widget.verses;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GitaVersePage(verses: verses, verse: verse),
        ),
      );
    }
  }

  // Navigate to next verse
  void _navigateToNextVerse() {
    if (index < widget.verses.length - 1) {
      final verse = widget.verses[index+1];
      final verses = widget.verses;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GitaVersePage(verses: verses, verse: verse),
        ),
      );
    }

  }

  bool _isFirstVerse() {
    return index == 0;
  }
  bool _isLastVerse() {
    return index == widget.verses.length - 1;
  }
  
  @override
  Widget build(BuildContext context) {
    final onlyAudio = (widget.verse.audioPath != null && widget.verse.audioPath!.isNotEmpty)
      && (widget.verse.sanskrit.isEmpty && widget.verse.english.isEmpty && (widget.verse.synonyms == null || widget.verse.synonyms.isEmpty) && widget.verse.translation.isEmpty && widget.verse.purport.isEmpty);
    final chapter = widget.verse.chapter.toString();
    final shloka = widget.verse.shloka.toString();
    final verseId = "$chapter:$shloka";
    final isBookmarked = _bookmarkedVerseIds.contains(verseId);
    return GestureDetector(
      onTap: () {
        if (_tooltipLocked) {
          setState(() {
            _tooltipLocked = false;
            _tooltipVisible = true;
          });
        }
      },
      // Add horizontal swipe gesture for navigation
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swipe right - go to previous verse
          if (!_isFirstVerse()) {
            _navigateToPreviousVerse();
          }
        } else if (details.primaryVelocity! < 0) {
          // Swipe left - go to next verse
          if (!_isLastVerse()) {
            _navigateToNextVerse();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Bhagavad Gita ${widget.verse.chapter}.${widget.verse.shloka}',
            style: TextStyle(color: color2),
          ),
          backgroundColor: color1,
          iconTheme: IconThemeData(color: color2),
          actions: [
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? color2 : color2,
              ),
              onPressed: () => _toggleBookmark(verseId),
            ),
            // Advanced view toggle in AppBar
            TextButton.icon(
              onPressed: _toggleAdvancedView,
              icon: Icon(
                _isAdvancedView ? Icons.tune : Icons.view_agenda,
                color: color2,
              ),
              label: Text(
                _isAdvancedView ? 'Advanced View' : 'Default View',
                style: TextStyle(color: color2),
              ),
            ),
          ],
        ),
        body: onlyAudio
          ? Center(
              child: AudioPlayerWidget(
                chapter: widget.verse.chapter.toString(),
                shloka: widget.verse.shloka.toString(),
                audioAssetPath: widget.verse.audioPath!,
                verseText: widget.verse.sanskrit.replaceAll('\n', ' '),
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // Advanced view controls - only show when in advanced mode
                    if (_isAdvancedView)
                      _buildAdvancedViewControls(),
                    
                    // Main content - all in a single scrollable column
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Main verse card
                            Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  // Card header
                                  Container(
                                    padding: const EdgeInsets.all(16.0),
                                    // decoration: const BoxDecoration(
                                    //   color: _GitaVersePageState.cardBackgroundColor,
                                    //   border: Border(
                                    //     bottom: BorderSide(
                                    //       color: _GitaVersePageState.dividerColor,
                                    //       width: 1.0,
                                    //     ),
                                    //   ),
                                    // ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Bhagavad Gita ${widget.verse.chapter}.${widget.verse.shloka}',
                                          style: TextStyle(
                                            fontSize: _GitaVersePageState.fontSizeHeading,
                                            fontWeight: FontWeight.bold,
                                            color: color2
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                            color: isBookmarked ? color2 : color2,
                                          ),
                                          onPressed: () => _toggleBookmark(verseId),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Card body - dynamic content based on visibility settings
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Sanskrit (Devanagari) section
                                        if (_showDevanagari && widget.verse.sanskrit.isNotEmpty) 
                                          _buildVerseSection(
                                            'Devanagari',
                                            widget.verse.sanskrit,
                                            false, // Not interactive
                                          ),
                                        
                                        if (_showDevanagari && _showTransliteration)
                                          const SizedBox(height: 24.0),
                                        
                                        // Transliteration section with interactive words
                                        if (_showTransliteration && widget.verse.english.isNotEmpty) 
                                          _buildVerseSection(
                                            'Verse Text (Transliteration)',
                                            widget.verse.english,
                                            true, // Interactive for hover tooltips
                                          ),
                                        
                                        if (_showSynonyms)
                                          const SizedBox(height: 24.0),
                                        
                                        // Word Meanings section
                                        if (_showSynonyms && widget.verse.synonyms.isNotEmpty)
                                          _buildExpandedSection(
                                            'Synonyms',
                                            _buildWordMeanings(),
                                          ),
                                        
                                        if (_showTranslation)
                                          const SizedBox(height: 24.0),
                                        
                                        // Translation section
                                        if (_showTranslation && widget.verse.translation.isNotEmpty)
                                          _buildExpandedSection(
                                            'Translation',
                                            Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Text(
                                                widget.verse.translation,
                                                style: const TextStyle(
                                                  fontSize: _GitaVersePageState.fontSizeBody, // Increased from 16 to 18
                                                  height: 1.6
                                                ),
                                                textAlign: TextAlign.justify,
                                              ),
                                            ),
                                          ),
                                        
                                        if (_showPurport)
                                          const SizedBox(height: 24.0),
                                        
                                        // Purport section
                                        if (_showPurport && widget.verse.purport.isNotEmpty)
                                          _buildExpandedSection(
                                            'Purport',
                                            Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: widget.verse.purport
                                                    .split('\n')
                                                    .map((line) => Text(
                                                          line,
                                                          style: const TextStyle(
                                                            fontSize: _GitaVersePageState.fontSizeBody,
                                                            height: 1.6,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                        ))
                                                    .toList(),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Audio player section
                                  if (widget.verse.audioPath != null)
                                    AudioPlayerWidget(
                                      chapter: widget.verse.chapter.toString(),
                                      shloka: widget.verse.shloka.toString(),
                                      audioAssetPath: 'assets/Audio/Bhagavad_gita_${widget.verse.chapter}.${widget.verse.shloka}.mp3',
                                      verseText: widget.verse.english,
                                    ),
                                ],
                              ),
                            ),        
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Tooltip overlay
                if (_tooltipVisible)
                  Positioned(
                    left: _tooltipPosition.dx,
                    top: _tooltipPosition.dy,
                    child: GestureDetector(
                      onTap: _toggleTooltipLock,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.all(12.0),
                        // decoration: BoxDecoration(
                        //   color: _GitaVersePageState.backgroundColor,
                        //   borderRadius: BorderRadius.circular(8.0),
                        //   boxShadow: [
                        //     BoxShadow(
                        //       color: Colors.black.withOpacity(0.2),
                        //       blurRadius: 6.0,
                        //       offset: const Offset(0, 2),
                        //     ),
                        //   ],
                        //   border: Border.all(
                        //     color: _tooltipLocked ? _GitaVersePageState.primaryColor : Colors.grey.shade300,
                        //     width: 1.0,
                        //   ),
                        // ),
                        child: Text(
                          _tooltipText,
                          style: const TextStyle(fontSize: _GitaVersePageState.fontSizeCaption),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        bottomNavigationBar: _buildNavigationButtons(),
      ),
    );
  }
  
  // Build the advanced view controls with toggle switches
  Widget _buildAdvancedViewControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      // decoration: BoxDecoration(
      //   // color: _GitaVersePageState.backgroundColor,
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.05),
      //       blurRadius: 4,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Show/Hide Sections',
            style: TextStyle(
              color: color2,
              fontSize: _GitaVersePageState.fontSizeSubheading,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            children: [
              _buildToggleSwitch('Devanagari', _showDevanagari, (value) {
                setState(() => _showDevanagari = value);
                _savePreference('showDevanagari', value);
              }),
              _buildToggleSwitch('Verse Text', _showTransliteration, (value) {
                setState(() => _showTransliteration = value);
                _savePreference('showTransliteration', value);
              }),
              _buildToggleSwitch('Synonyms', _showSynonyms, (value) {
                setState(() => _showSynonyms = value);
                _savePreference('showSynonyms', value);
              }),
              _buildToggleSwitch('Translation', _showTranslation, (value) {
                setState(() => _showTranslation = value);
                _savePreference('showTranslation', value);
              }),
              _buildToggleSwitch('Purport', _showPurport, (value) {
                setState(() => _showPurport = value);
                _savePreference('showPurport', value);
              }),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build a toggle switch with label
  Widget _buildToggleSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color1,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildVerseSection(String title, String content, bool interactive) {
    final lines = content.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: _GitaVersePageState.fontSizeHeading,
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        const SizedBox(height: 12.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          // decoration: BoxDecoration(
          //   color: _GitaVersePageState.verseBgColor,
          //   borderRadius: BorderRadius.circular(8.0),
          // ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: lines.map((line) {
              if (interactive) {
                return _buildInteractiveLine(line);
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: _GitaVersePageState.fontSizeBody, 
                      height: 1.5
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveLine(String line) {
    // Split the line into words, preserving punctuation
    final rawWords = line.split(RegExp('(\\s+)'));

    final List<Map<String, dynamic>> processedWords = [];

    // Create a map of synonyms for easier lookup
    final synonymMap = <String, String>{};
    for (var entry in widget.verse.synonyms.entries) {
      synonymMap[entry.key.toLowerCase()] = entry.value.meaning;
    }

    // Track which synonyms have already been matched in this line
    final Set<String> usedSynonyms = {};

    // Process each word in the line
    for (String rawWord in rawWords) {
      if (rawWord.trim().isEmpty) continue;
      final wordData = _processWordWithMeaningUnique(rawWord, synonymMap, usedSynonyms);
      processedWords.addAll(wordData);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // First row: Display the original line
          // Text(
          //   line,
          //   style: const TextStyle(
          //     fontSize: fontSizeSanskrit,
          //     color: textPrimaryColor,
          //     fontWeight: FontWeight.w500,
          //   ),
          //   textAlign: TextAlign.center,
          // ),
          const SizedBox(height: 12.0),
          // Second row: Word-by-word breakdown with meanings
          _buildWordMeaningRow(processedWords),
        ],
      ),
    );
  }

  // Process a single word and find its meaning(s), ensuring unique synonym usage and prioritizing longest match
  List<Map<String, dynamic>> _processWordWithMeaningUnique(String rawWord, Map<String, String> synonymMap, Set<String> usedSynonyms) {
    final List<Map<String, dynamic>> results = [];
    String cleanWord = rawWord;
    debugPrint('Processing word: $rawWord, Cleaned: $cleanWord');

    // Try to match the longest possible synonym first
    String? meaning = _findLongestWordMeaningUnique(cleanWord, synonymMap, usedSynonyms);
    if (meaning != null) {
      results.add({
        'word': rawWord,
        'meaning': meaning,
        'cleanWord': cleanWord,
      });
    } else {
      // Try to split compound words and match each part
      final splitResults = _splitAndFindMeaningsUnique(rawWord, cleanWord, synonymMap, usedSynonyms);
      results.addAll(splitResults);
    }
    return results;
  }

  // Find the longest matching synonym for a word, skipping already used synonyms
  String? _findLongestWordMeaningUnique(String cleanWord, Map<String, String> synonymMap, Set<String> usedSynonyms) {
    final lowerWord = cleanWord.toLowerCase();
    String? bestKey;
    int bestLength = 0;
    // Check all unused synonyms for the longest match
    for (var entry in synonymMap.entries) {
      final synonymKey = entry.key.toLowerCase();
      if (usedSynonyms.contains(synonymKey)) continue;
      if (_wordsMatch(lowerWord, synonymKey) && synonymKey.length > bestLength) {
        bestKey = synonymKey;
        bestLength = synonymKey.length;
      }
    }
    if (bestKey != null) {
      usedSynonyms.add(bestKey);
      return synonymMap[bestKey];
    }
    return null;
  }
  
  // Find word meaning, accepting any match not just the longest
  String? _findWordMeaningUnique(String cleanWord, Map<String, String> synonymMap, Set<String> usedSynonyms) {
    final lowerWord = cleanWord.toLowerCase();
    
    // Check all unused synonyms for any match
    for (var entry in synonymMap.entries) {
      final synonymKey = entry.key.toLowerCase();
      if (usedSynonyms.contains(synonymKey)) continue;
      if (_wordsMatch(lowerWord, synonymKey)) {
        usedSynonyms.add(synonymKey);
        return synonymMap[synonymKey];
      }
    }
    return null;
  }

  // Split compound words and find meanings for each part, ensuring unique synonym usage
  List<Map<String, dynamic>> _splitAndFindMeaningsUnique(String originalWord, String cleanWord, Map<String, String> synonymMap, Set<String> usedSynonyms) {
    final List<Map<String, dynamic>> results = [];
    List<String> parts = [];
    if (cleanWord.contains('-')) {
      parts = cleanWord.split('-');
    } else {
      parts = _intelligentWordSplit(cleanWord, synonymMap);
    }
    if (parts.length > 1) {
      String remainingOriginal = originalWord;
      for (int i = 0; i < parts.length; i++) {
        String part = parts[i];
        String? meaning = _findWordMeaningUnique(part, synonymMap, usedSynonyms);
        String displayPart = _extractDisplayPart(remainingOriginal, part, i == parts.length - 1);
        results.add({
          'word': displayPart,
          'meaning': meaning,
          'cleanWord': part,
          'isPart': true,
        });
        remainingOriginal = remainingOriginal.replaceFirst(displayPart.replaceAll(RegExp(r'[^\w\-]'), ''), '');
      }
    } else {
      results.add({
        'word': originalWord,
        'meaning': null,
        'cleanWord': cleanWord,
      });
    }
    return results;
  }

  // Intelligent word splitting based on synonym patterns
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

  // Try to split a word based on a pattern from synonyms
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

  // Extract the display part from original word
  String _extractDisplayPart(String originalWord, String cleanPart, bool isLast) {
    final cleanOriginal = originalWord.replaceAll(RegExp(r'[^\w\-]'), '').toLowerCase();
    final cleanPartLower = cleanPart.toLowerCase();
    
    final index = cleanOriginal.indexOf(cleanPartLower);
    if (index >= 0) {
      int endIndex = index + cleanPart.length;
      if (isLast) {
        endIndex = originalWord.length;
      }
      return originalWord.substring(index, endIndex.clamp(0, originalWord.length));
    }
    
    return cleanPart;
  }

  // Check if two words match using various strategies
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

  // Normalize Sanskrit transliteration
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

  // Build the word-meaning display row
  Widget _buildWordMeaningRow(List<Map<String, dynamic>> processedWords) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing:4.0,
      children: processedWords.map((wordData) {
        final word = wordData['word'] as String;
        final meaning = wordData['meaning'] as String?;
        final isPart = wordData['isPart'] as bool? ?? false;
        final customMeaning = _customMeanings[word];
        return GestureDetector(
          onDoubleTap: () => _addOrEditCustomMeaning(word, customMeaning ?? meaning),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: (customMeaning != null || meaning != null) ? color3 : color3,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: (customMeaning != null || meaning != null) ? color3 : color3,
                width: 0.1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      word,
                      style: TextStyle(
                        fontSize: isPart ? fontSizeMeaning + 2 : fontSizeMeaning + 4,
                        fontWeight: FontWeight.w600,
                        color: (customMeaning != null || meaning != null) ? color2 : color2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // const SizedBox(width: 2),
                    // GestureDetector(
                    //   onTap: () => _addOrEditCustomMeaning(word, customMeaning ?? meaning),
                    //   child: const Icon(Icons.edit, size: 14, color: Colors.blueGrey),
                    // ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  customMeaning ?? meaning ?? '?',
                  style: TextStyle(
                    fontSize: fontSizeMeaning,
                    color: customMeaning != null
                        ? color2
                        : (meaning != null ? Colors.grey.shade700 : Colors.grey.shade400),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _loadCustomMeanings() async {
    final prefs = await SharedPreferences.getInstance();
    final keyPrefix = _customMeaningPrefix();
    final keys = prefs.getKeys().where((k) => k.startsWith(keyPrefix));
    final map = <String, String>{};
    for (final k in keys) {
      final word = k.substring(keyPrefix.length);
      final value = prefs.getString(k);
      if (value != null) map[word] = value;
    }
    setState(() {
      _customMeanings = map;
    });
  }

  String _customMeaningPrefix() {
    return 'custom_meaning_${widget.verse.chapter}_${widget.verse.shloka}_';
  }

  Future<void> _addOrEditCustomMeaning(String word, String? currentMeaning) async {
    final controller = TextEditingController(text: currentMeaning ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add/Edit Meaning for "$word"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter custom meaning'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final key = _customMeaningPrefix() + word;
      await prefs.setString(key, result);
      setState(() {
        _customMeanings[word] = result;
      });
    }
  }

  Widget _buildWordMeanings() {
    if (widget.verse.synonyms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No word meanings available for this verse.',
          style: TextStyle(
            fontSize: fontSizeCaption,
            color: textSecondaryColor,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Create a single paragraph with all word meanings
    final List<InlineSpan> spans = [];
    final entries = widget.verse.synonyms.entries.toList();
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      // Add the word in bold
      spans.add(
        TextSpan(
          text: entry.key,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
      );
      
      // Add the dash separator
      spans.add(
        const TextSpan(
          text: ' — ',
          style: TextStyle(
            color: textPrimaryColor,
          ),
        ),
      );
      
      // Add the meaning
      spans.add(
        TextSpan(
          text: entry.value.meaning,
          style: const TextStyle(
            color: textPrimaryColor,
          ),
        ),
      );
      
      // Add semicolon separator if not the last entry
      if (i < entries.length - 1) {
        spans.add(
          const TextSpan(
            text: '; ',
            style: TextStyle(
              color: textPrimaryColor,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: fontSizeCaption,
            color: textPrimaryColor,
            height: 1.4,
          ),
          children: spans,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildExpandedSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSizeSubheading,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: dividerColor),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildAudioPlayerControls() {
    return Column(
      children: [
        // Error message display
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: errorColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: errorColor, size: 20),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: errorColor,
                      fontSize: fontSizeCaption,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Main audio controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play/Pause button
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _playAudio,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
            
            const SizedBox(width: 16.0),
            
            // Time display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatTime(_position)} / ${_formatTime(_duration)}',
                  style: const TextStyle(
                    fontSize: fontSizeCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Container(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color1),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Audio path debug info (only in debug mode)
        if (widget.verse.audioPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Audio: ${widget.verse.audioPath}',
              style: TextStyle(
                fontSize: fontSizeSmall,
                color: textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildAudioComingSoon() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, color: Colors.grey.shade600),
          const SizedBox(width: 8.0),
          Text(
            'Audio recitation coming soon',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: fontSizeCaption,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous verse button
          ElevatedButton.icon(
            onPressed:  _navigateToPreviousVerse,
            icon: Icon(Icons.arrow_back , color: color2),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: color2,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            ),
          ),
          
          // Next verse button
          ElevatedButton.icon(
            onPressed: _navigateToNextVerse,
            icon: Icon(Icons.arrow_forward, color: color2),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: color2,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            ),
          )

        ],
      ),
    );
  }




}

// unused functions
/*
void _loadWordMeanings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if word meanings are already processed and stored
      final lines = widget.verse.english.split('\n');

      for (String line in lines) {
        if (line.trim().isEmpty) continue;

        // Try to get pre-processed meanings for this line
        final processedWords = await _wordMeaningService.getVerseWordMeanings(
          widget.verse.chapter,
          widget.verse.shloka,
          line
        );

        if (processedWords == null || processedWords.isEmpty) {
          // Process and store meanings for this verse
          await _wordMeaningService.processAndStoreVerseMeanings(widget.verse);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading word meanings: $e');
      setState(() {
        _errorMessage = 'Error loading word meanings';
        _isLoading = false;
      });
    }
  }

* */
