import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verse_repository.dart';
import 'package:sanskrit_racitatiion_project/bookmark_screen/bookmark_manager.dart';

class GitaVersePage extends StatefulWidget {
  final Verse_1 verse;
  final void Function(bool)? onNavigate; // Callback for navigation
  
  const GitaVersePage({
    super.key, 
    required this.verse, 
    this.onNavigate,
  });

  @override
  State<GitaVersePage> createState() => _GitaVersePageState();
}

class _GitaVersePageState extends State<GitaVersePage> {
  // UI Constants for consistent theming
  // Colors
  static const Color primaryColor = Colors.deepOrangeAccent;
  static const Color dividerColor = Color(0xFFE9ECEF);
  static const Color textPrimaryColor = Colors.black;
  static const Color textSecondaryColor = Colors.grey;
  static const Color errorColor = Colors.red;
  
  // Font Sizes
  static const double fontSizeHeading = 18.0;
  static const double fontSizeSubheading = 16.0;
  static const double fontSizeBody = 18.0;
  static const double fontSizeCaption = 14.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeSanskrit = 25.0;  // For Sanskrit words
  static const double fontSizeMeaning = 16.0;   // For word meanings
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  String? _errorMessage;
  bool _isLoading = false;
  late String _selectedAudio;
  late Map<String, String> _audioFiles;
  Set<String> _selectedViews = {};
  bool isBookmarked = false;
  String get verseId => '${widget.verse.chapter}:${widget.verse.shloka}';


  // For tooltip display
  bool _tooltipVisible = true;
  String _tooltipText = '';
  Offset _tooltipPosition = Offset.zero;
  bool _tooltipLocked = false;
  
  // For custom meanings
  Map<String, String> _customMeanings = {};
  String? _currentSelectedSegment;
  final TextEditingController _meaningController = TextEditingController();
  
  // For view modes
  bool _isAdvancedView = false;
  
  // For content visibility
  bool _showDevanagari = true;
  bool _showTransliteration = true;
  bool _showSynonyms = true; // Changed to true by default
  bool _showTranslation = true;
  bool _showPurport = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
    
    // Set up audio player if audio path is available
    if (widget.verse.audioPath != null) {
      _setupAudioPlayer();
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

  void _showTooltip(String text, Offset position) {
    setState(() {
      _tooltipText = text;
      _tooltipPosition = position;
      _tooltipVisible = true;
    });
  }

  void _hideTooltip() {
    if (!_tooltipLocked) {
      setState(() {
        _tooltipVisible = false;
      });
    }
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

//   // Navigate to previous verse
//   void _navigateToPreviousVerse() {
//     if (widget.onNavigate != null) {
//       // Direct navigation without alert
//       widget.onNavigate!(false);
//     } else {
//       // Fallback if no navigation callback provided
//       Navigator.pop(context);
//     }
//   }

//   // Navigate to next verse
//   void _navigateToNextVerse() {
//     // Check if this is the last verse
//     if (_isLastVerse()) {
//       // Show feedback that this is the last verse
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('This is the last verse in this chapter'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
    
//     if (widget.onNavigate != null) {
//       // Direct navigation to next verse
//       widget.onNavigate!(true);
//     } else {
//       // Get current verse details
//       final currentChapter = widget.verse.chapter;
//       final currentShloka = int.parse(widget.verse.shloka.toString());
      
//       // Calculate next verse
//       final nextShloka = (currentShloka + 1).toString();
      
//       // Here you would typically fetch the next verse from your data source
//       // This is a placeholder - you need to implement verse fetching logic
//       // based on your actual data structure
      

      
//       // For now, just show a message that navigation isn't implemented
//       ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Navigation to specific verses not implemented yet'),
//         duration: Duration(seconds: 2),
//       ),
//       );
//       // Fallback if no navigation callback provided
//       Navigator.pop(context);
//     }
//   }

//   // Check if this is the first verse in the chapter
//   bool _isFirstVerse() {
//     return widget.verse.shloka == 1;
//   }

//   // Check if this is the last verse in the chapter
//   bool _isLastVerse() {
//     // This is a simplified implementation. In a real app, you would check against the actual number of verses in each chapter.
//     // Placeholder logic - replace with actual chapter verse counts
//     Map<int, int> chapterVerseCount = {
//       1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47,
//       7: 30, 8: 28, 9: 34, 10: 42, 11: 55, 12: 20,
//       13: 35, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78
//     };
    
//     int? totalVerses = chapterVerseCount[int.parse(widget.verse.chapter.toString())];
//     return totalVerses != null && int.parse(widget.verse.shloka.toString()) == totalVerses;
//   }
  
  

      // Toggle the selected view
      if (_selectedViews.contains(view)) {
        _selectedViews.remove(view);
      } else {
        _selectedViews.add(view);
      }

      // Clear all first
      _showSanskrit = false;
      _showEnglish = false;
      _showWordMeanings = false;
      _showTranslation = false;
      _showPurport = false;

      // If 'All' is selected, show everything
      if (_selectedViews.contains('All')) {
        _showSanskrit = true;
        _showEnglish = true;
        _showWordMeanings = true;
        _showTranslation = true;
        _showPurport = true;
      } else {
        // Enable based on selected individual views
        if (_selectedViews.contains('Sanskrit')) _showSanskrit = true;
        if (_selectedViews.contains('English')) {
          _showEnglish = true;
        }
        if (_selectedViews.contains('Word Meanings')) _showWordMeanings = true;
        if (_selectedViews.contains('Translation')) _showTranslation = true;
        if (_selectedViews.contains('Purport')) _showPurport = true;
      }
    });
  }

  void _loadBookmarkStatus() async {
    bool bookmarked = await BookmarkManager.isBookmarked(verseId);
    setState(() {
      isBookmarked = bookmarked;
    });
  }

  void _toggleBookmark() async {
    if (isBookmarked) {
      await BookmarkManager.removeBookmark(verseId);
    } else {
      await BookmarkManager.addBookmark(verseId);
    }

    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(color: Color(0xFFFF9933)),
          ),

          backgroundColor: _GitaVersePageState.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Advanced view toggle in AppBar
            TextButton.icon(
              onPressed: _toggleAdvancedView,
              icon: Icon(
                _isAdvancedView ? Icons.tune : Icons.view_agenda,
                color: Colors.white,
              ),
              label: Text(
                _isAdvancedView ? 'Advanced View' : 'Default View',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],

        ),
        body: Stack(
          children: [
            Column(
              children: [
                // View selection row
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    children: _viewOptions.map((view) => 
                      _buildViewOption(view),
                    ).toList(),
                  ),
                ),
                
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

                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFE0B2),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE9ECEF),
                                      width: 1.0,
                                    ),
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Bhagavad Gita ${widget.verse.chapter}.${widget.verse.shloka}',
                                      style: const TextStyle(

                                        fontSize: _GitaVersePageState.fontSizeHeading,

                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C2C54),
                                      ),
                                    ),
                                    IconButton(


                                      icon: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        color: isBookmarked ? Colors.orange : Colors.white,
                                      ),
                                      onPressed: _toggleBookmark,
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
                                          child: Text(
                                            widget.verse.purport,
                                            style: const TextStyle(fontSize: _GitaVersePageState.fontSizeBody, height: 1.6), // Increased from 16 to 18
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Audio player section

                              Container(
                                padding: const EdgeInsets.all(16.0),
                                // decoration: const BoxDecoration(
                                //   color: _GitaVersePageState.cardBackgroundColor,
                                //   border: Border(
                                //     top: BorderSide(
                                //       color: _GitaVersePageState.dividerColor,
                                //       width: 1.0,
                                //     ),
                                //   ),
                                // ),
                                child: widget.verse.audioPath != null
                                  ? _buildAudioPlayerControls()
                                 : _buildAudioComingSoon(),
                              ),

                            ],
                          ),
                        ),
                        
                        // Navigation buttons
                        _buildNavigationButtons(),
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

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: _tooltipLocked ? Color(0xFF2C2C54) : Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),

                    child: Text(
                      _tooltipText,
                      style: const TextStyle(fontSize: _GitaVersePageState.fontSizeCaption),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
// <<<<<<< main
  
  // Build the advanced view controls with toggle switches
  Widget _buildAdvancedViewControls() {
// =======

//   Widget _buildViewOption(String view) {
//     final isSelected = _selectedViews.contains(view);

//     return GestureDetector(
//       onTap: () {
//         _updateVisibility(view);
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF2C2C54) : Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(20.0),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF2C2C54) : Colors.grey.shade300,
//             width: 1.0,
//           ),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           view,
//           style: TextStyle(
//             color: isSelected ? const Color(0xFFFF9933) : Colors.black87,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             fontSize: 14.0,
//           ),
//         ),
//       ),
//     );
//   }


//   Widget _buildBreadcrumb() {
// >>>>>>> main
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
// <<<<<<< main
          const Text(
            'Show/Hide Sections',
            style: TextStyle(
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
              }),
              _buildToggleSwitch('Verse Text', _showTransliteration, (value) {
                setState(() => _showTransliteration = value);
              }),
              _buildToggleSwitch('Synonyms', _showSynonyms, (value) {
                setState(() => _showSynonyms = value);
              }),
              _buildToggleSwitch('Translation', _showTranslation, (value) {
                setState(() => _showTranslation = value);
              }),
              _buildToggleSwitch('Purport', _showPurport, (value) {
                setState(() => _showPurport = value);
              }),
            ],
// =======
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//               minimumSize: Size.zero,
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             child: const Text('Scriptures', style: TextStyle(color: Color(0xFF2C2C54))),
//           ),
//           const Text(' / ', style: TextStyle(color: Color(0xFF2C2C54))),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//               minimumSize: Size.zero,
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             child: const Text('Bhagavad Gita', style: TextStyle(color: Color(0xFF2C2C54))),
//           ),
//           const Text(' / ', style: TextStyle(color: Color(0xFF2C2C54))),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//               minimumSize: Size.zero,
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             child: Text('Chapter ${widget.verse.chapter}', style: TextStyle(color: Color(0xFF2C2C54))),
//           ),
//           const Text(' / ', style: TextStyle(color: Color(0xFF2C2C54))),
//           Text(
//             'Verse ${widget.verse.shloka}',
//             style: const TextStyle(color: Color(0xFF2C2C54), fontWeight: FontWeight.bold),

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
          activeColor: _GitaVersePageState.primaryColor,
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
          style: const TextStyle(
            fontSize: _GitaVersePageState.fontSizeHeading,
            fontWeight: FontWeight.bold,
            color: _GitaVersePageState.primaryColor,

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
    final rawWords = line.split(RegExp(r"[ ’ ]")); // there is another ’ in the line so we need to split the line with space
    final List<String> words = [];
    final List<String?> meanings = [];
    final Set<String> usedSynonyms = {};
    final List<String> final_Words = [];
    
    // Process all words, including hyphenated ones
    for (String rawWord in rawWords) {
      if (rawWord.contains('-')) {
        // Split hyphenated words
        final parts = rawWord.split('-');

        for (int i = 0; i < parts.length; i++) {
          String part = parts[i];
          // // Add hyphen back except for the last part
          if (i==0) {
            part = '$part-';
          }
          words.add(part);
        }
      } else if (rawWord.contains('\'')) {
        // Handle words with apostrophes
        final parts = rawWord.split('\'');
        for (String part in parts) {
          if (parts.indexOf(part) == 0) {
            part =  "$part'";
          }
          words.add(part);
        }
      } else if (rawWord.contains(',')) {
        // Handle words with commas
        final parts = rawWord.split(',');
        for (String part in parts) {
          // add comma back except for the first part
          if (parts.indexOf(part) == 0) {
            part =  "$part,";
          }
          words.add(part);
        }
      }  else {
        words.add(rawWord);
      }
    }
    
    // Find meanings for each word
    for (String word in words) {
      String? meaning;
      print('Word: $word');
      
      // Clean the word for comparison (remove punctuation)
      String cleanWord = word;
      // Check if this word has a synonym in the verse data
      for (var entry in widget.verse.synonyms.entries) {
        // Skip if this synonym key has already been used
        if (usedSynonyms.contains(entry.key)) continue;
        
        String cleanKey = entry.key.toLowerCase();
        print('$cleanKey $cleanWord');
        // Check if t`he first 70 percent part of the word matches with first part of synonyms
        if (cleanWord.length < 3 || cleanKey.length < 3) {
          if (cleanWord == cleanKey) {
            meaning = entry.value.meaning;
            usedSynonyms.add(entry.key);
            break;

//   Widget _buildInteractiveLine(String line, bool isFullView) {
//     final words = line.split(' ');

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Wrap(
//         alignment: WrapAlignment.center,
//         spacing: 4.0,
//         runSpacing: 4.0,
//         children: words.map((word) {
//           String? meaning;
//           for (var entry in widget.verse.synonyms.entries) {
//             if (word.toLowerCase().contains(entry.key.toLowerCase()) ||
//                 entry.key.toLowerCase().contains(word.toLowerCase())) {
//               meaning = entry.value.meaning;
//               break;
//             }

          }
        } else if (cleanWord.startsWith(cleanKey.substring(0, (cleanKey.length * 0.5).round()))) {
          meaning = entry.value.meaning;
          usedSynonyms.add(entry.key);
          break;
        } 
        else if (cleanWord.contains(cleanKey.substring(0, (cleanKey.length * 0.5).round()))) {
          meaning = entry.value.meaning;
          usedSynonyms.add(entry.key);
          break;
        }
        else if (cleanKey.contains(cleanWord.substring(0, (cleanWord.length * 0.5).round()))) {
          meaning = entry.value.meaning;
          usedSynonyms.add(entry.key);
          break;
        }
        else if (cleanKey.startsWith(cleanWord.substring(0, (cleanWord.length * 0.5).round()))) {
          meaning = entry.value.meaning;
          usedSynonyms.add(entry.key);
          break;
        }
      }
      
      // // Check for custom meaning
      // if (_customMeanings.containsKey(word)) {
      //   meaning = _customMeanings[word];
      // } else {
      //   meaning ??= ' ';
      // }
      // if no meaning found then append the present word to previous word part and store the final word in a new list
      if (meaning == null) {
        // add the word to the previous word part
        word = final_Words.isNotEmpty ? final_Words.last + word : word;
        if (final_Words.isNotEmpty) {
          final_Words.removeLast();
        }
        final_Words.add(word);
      } else {
        // add the word to the final words list
        final_Words.add(word);
      }
      // Store the meaning in the list
      meanings.add(meaning);

        
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // First line: Display the original line with all words
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: fontSizeSanskrit,
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w500,

//           return GestureDetector(
//             onTapDown: (details) {
//               if (meaning != null) {
//                 final Offset position = details.globalPosition;
//                 _showTooltip('$word: $meaning', Offset(position.dx, position.dy + 20));
//               }
//             },
//             onTap: () {
//               if (meaning != null) {
//                 _toggleTooltipLock();
//               }
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
//               decoration: BoxDecoration(
//                 border: meaning != null
//                     ? const Border(bottom: BorderSide(color: Color(0xFF2C2C54), width: 1.0))
//                     : null,
//               ),
//               child: Text(
//                 word,
//                 style: TextStyle(
//                   fontSize: isFullView ? 22 : 18,
//                   color: meaning != null ? Color(0xFF2C2C54) : Colors.black87,

                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Second line: Meanings aligned with each word
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.start,
                children: List.generate(final_Words.length, (index) {
                  final word = final_Words[index];
                  final meaning = meanings[index];
                  
                  // Calculate approximate width for word
                  final wordWidth = (word.length * fontSizeSanskrit * 1).clamp(30.0, 200.0);
                  
                  return SizedBox(
                    width: wordWidth,
                    // padding: const EdgeInsets.only(right: 2.0),
                    // margin: const EdgeInsets.only(bottom: 4.0),
                    child: meaning != null ? Text(
                      meaning,
                      style: const TextStyle(
                        fontSize: fontSizeMeaning,
                        color: textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ) : const SizedBox.shrink( // If no meaning, show empty space
                
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Add a method to show dialog to add a new meaning
  void _showAddMeaningDialog(String word) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add meaning for "$word"'),
          content: TextField(
            controller: _meaningController,
            decoration: const InputDecoration(
              hintText: 'Enter the meaning',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _meaningController.clear();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _GitaVersePageState.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_meaningController.text.isNotEmpty) {
                  setState(() {
                    _customMeanings[word] = _meaningController.text;
                  });
                  Navigator.pop(context);
                  _meaningController.clear();
                  
                  // Show a confirmation snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Meaning added for "$word"'),
                      backgroundColor: _GitaVersePageState.primaryColor,
                    ),
                  );
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }


  Widget _buildExpandedSection(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _GitaVersePageState.dividerColor),
        borderRadius: BorderRadius.circular(4.0),
      ),
      elevation: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: _GitaVersePageState.fontSizeHeading,
                    fontWeight: FontWeight.bold,
                    color: _GitaVersePageState.primaryColor,

                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _GitaVersePageState.dividerColor, height: 1),
          content,
        ],
      ),
    );
  }

  Widget _buildWordMeanings() {
    if (widget.verse.synonyms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Word-by-word meanings are not available for this verse.',
          style: TextStyle(fontSize: _GitaVersePageState.fontSizeBody),
        ),
      );
    }

    // Create a single string with the format:
    // sanskrit1 — meaning1; sanskrit2 — meaning2; ...
    String formattedMeanings = '';
    widget.verse.synonyms.entries.forEach((entry) {
      if (formattedMeanings.isNotEmpty) {
        formattedMeanings += '; ';
      }
      formattedMeanings += '${entry.key} — ${entry.value.meaning}';
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        formattedMeanings,
        style: const TextStyle(
          fontSize: _GitaVersePageState.fontSizeBody,
          height: 1.6,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
  
  // Build navigation buttons
  Widget _buildNavigationButtons() {
    bool isFirst = _isFirstVerse();
    bool isLast = _isLastVerse();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous verse button - left side
          if (!isFirst)
            ElevatedButton.icon(
              onPressed: _navigateToPreviousVerse,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous Verse'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // Fix: Set text color to white
                backgroundColor: _GitaVersePageState.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
            ), // Add ripple effect for better feedback
          // Spacer when only one button is shown
          if (isFirst && !isLast || !isFirst && isLast)
            const Spacer(),
          // Next verse button - right side
          if (!isLast)
            _addRippleEffect(
              ElevatedButton.icon(
                onPressed: _navigateToNextVerse,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Verse'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: _GitaVersePageState.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

//       padding: EdgeInsets.all(isFullView ? 0.0 : 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: widget.verse.synonyms.entries.map((entry) {
//           return Container(
//             margin: const EdgeInsets.only(bottom: 16.0),
//             padding: const EdgeInsets.all(12.0),
//             decoration: BoxDecoration(
//               color: isFullView ? Colors.grey.shade50 : null,
//               borderRadius: isFullView ? BorderRadius.circular(8.0) : null,
//               border: isFullView ? Border.all(color: Colors.grey.shade200) : null,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   entry.key,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: isFullView ? 18 : 16,
//                     color: Color(0xFF2C2C54),
//                   ),
//                 ),
//                 const SizedBox(height: 8.0),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Word: ",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: isFullView ? 16 : 14,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Expanded(
//                       child: Text(
//                         entry.value.versetext,
//                         style: TextStyle(
//                           fontSize: isFullView ? 16 : 14,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4.0),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Meaning: ",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: isFullView ? 16 : 14,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Expanded(
//                       child: Text(
//                         entry.value.meaning,
//                         style: TextStyle(
//                           fontSize: isFullView ? 16 : 14,
//                         ),
//                       ),
//                     ),
//                   ],

                ),
              )
            ), // Add ripple effect for better feedback
        ],
      ),
    );
  }
  
  // Helper method to add ripple effect to buttons
  Widget _addRippleEffect(Widget widget) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.white.withAlpha(77),
        highlightColor: Colors.white.withAlpha(26),
        child: widget,
      ),
    );
  }
  
  Widget _buildAudioPlayerControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Audio Recitation',
          style: TextStyle(
            fontSize: _GitaVersePageState.fontSizeHeading,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C54),
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            IconButton(
              onPressed: _isLoading ? null : _playAudio,
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
              iconSize: 48.0,
              color: _GitaVersePageState.primaryColor,
              disabledColor: _GitaVersePageState.textSecondaryColor,

            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xFF2C2C54),
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Color(0xFF2C2C54),
                      overlayColor: Colors.deepPurple.withOpacity(0.2),
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble(),
                      onChanged: (value) async {
                        await _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_position),
                          style: const TextStyle(
                            color: _GitaVersePageState.textSecondaryColor,
                            fontSize: _GitaVersePageState.fontSizeSmall,
                          ),
                        ),
                        Text(
                          _formatTime(_duration),
                          style: const TextStyle(
                            color: _GitaVersePageState.textSecondaryColor,
                            fontSize: _GitaVersePageState.fontSizeSmall,
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Loading audio...',
              style: TextStyle(
                color: _GitaVersePageState.textSecondaryColor,
                fontSize: _GitaVersePageState.fontSizeCaption,
              ),
            ),
          ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: _GitaVersePageState.errorColor,
                fontSize: _GitaVersePageState.fontSizeCaption,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildAudioComingSoon() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Audio Recitation',
          style: TextStyle(
            fontSize: _GitaVersePageState.fontSizeHeading,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        Text(
          'Audio recitation coming soon for this verse.',
          style: TextStyle(
            color: _GitaVersePageState.textSecondaryColor,
            fontSize: _GitaVersePageState.fontSizeCaption,
          ),
        ),
      ],
    );
  }
}


