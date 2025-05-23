import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;
  bool _isLoading = false;
  
  // For tooltip display
  bool _tooltipVisible = false;
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
  bool _showSynonyms = false; // Changed to true by default
  bool _showTranslation = true;
  bool _showPurport = false;

  @override
  void initState() {
    super.initState();
    
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

  // Navigate to previous verse
  void _navigateToPreviousVerse() {
    if (widget.onNavigate != null) {
      // Direct navigation without alert
      widget.onNavigate!(false);
    } else {
      // Fallback if no navigation callback provided
      Navigator.pop(context);
    }
  }

  // Navigate to next verse
  void _navigateToNextVerse() {
    if (widget.onNavigate != null) {
      // Direct navigation without alert
      widget.onNavigate!(true);
    } else {
      // Fallback if no navigation callback provided
      Navigator.pop(context);
    }
  }

  // Check if this is the first verse in the chapter
  bool _isFirstVerse() {
    return widget.verse.shloka == 1;
  }

  // Check if this is the last verse in the chapter
  bool _isLastVerse() {
    // This is a simplified implementation. In a real app, you would check against the actual number of verses in each chapter.
    // Placeholder logic - replace with actual chapter verse counts
    Map<int, int> chapterVerseCount = {
      1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47,
      7: 30, 8: 28, 9: 34, 10: 42, 11: 55, 12: 20,
      13: 35, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78
    };
    
    int? totalVerses = chapterVerseCount[widget.verse.chapter];
    return totalVerses != null && widget.verse.shloka == totalVerses;
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_tooltipLocked) {
          setState(() {
            _tooltipLocked = false;
            _tooltipVisible = false;
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
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepPurpleAccent,
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
                // Advanced view controls - only show when in advanced mode
                if (_isAdvancedView)
                  _buildAdvancedViewControls(),
                
                // Main content - all in a single scrollable column
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FA),
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark_add_outlined),
                                      color: Colors.deepPurpleAccent,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Bookmark feature coming soon'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Card body - dynamic content based on visibility settings
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                              fontSize: 16, 
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
                                            style: const TextStyle(fontSize: 16, height: 1.6),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  border: Border(
                                    top: BorderSide(
                                      color: Color(0xFFE9ECEF),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
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
                        color: _tooltipLocked ? Colors.deepPurpleAccent : Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      _tooltipText,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Build the advanced view controls with toggle switches
  Widget _buildAdvancedViewControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Show/Hide Sections',
            style: TextStyle(
              fontSize: 16,
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
          activeColor: Colors.deepPurpleAccent,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildVerseSection(String title, String content, bool interactive) {
    final lines = content.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurpleAccent,
          ),
        ),
        const SizedBox(height: 12.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: lines.map((line) {
              if (interactive) {
                return _buildInteractiveLine(line);
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 18, 
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
    final words = line.split(' ');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8C8DC), // Pink background color matching the image
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 24.0, // More space between lines
          children: words.map((word) {
            // Check if this word has a synonym in the verse data
            String? meaning;
            for (var entry in widget.verse.synonyms.entries) {
              if (word.toLowerCase().contains(entry.key.toLowerCase()) ||
                  entry.key.toLowerCase().contains(word.toLowerCase())) {
                meaning = entry.value.meaning;
                break;
              }
            }
            
            // Check if there's a custom meaning added by user
            if (_customMeanings.containsKey(word)) {
              meaning = _customMeanings[word];
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sanskrit word text in larger font
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Show meaning below the word in light gray
                Text(
                  meaning ?? ' ', // Show space if no meaning
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }).toList(),
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
                backgroundColor: Colors.deepPurpleAccent,
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
                      backgroundColor: Colors.deepPurpleAccent,
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
        side: const BorderSide(color: Color(0xFFE9ECEF)),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade300, height: 1),
          content,
        ],
      ),
    );
  }

  Widget _buildWordMeanings() {
    if (widget.verse.synonyms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Word-by-word meanings are not available for this verse.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.verse.synonyms.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Word: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.versetext,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Meaning: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.meaning,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
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
                foregroundColor: Colors.white, 
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
            ),
          // Spacer when only one button is shown
          if (isFirst && !isLast || !isFirst && isLast)
            const Spacer(),
          // Next verse button - right side
          if (!isLast)
            ElevatedButton.icon(
              onPressed: _navigateToNextVerse,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Verse'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAudioPlayerControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio Recitation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            IconButton(
              onPressed: _isLoading ? null : _playAudio,
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
              iconSize: 48.0,
              color: Colors.deepPurpleAccent,
              disabledColor: Colors.grey,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble(),
                    min: 0,
                    activeColor: Colors.deepPurpleAccent,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: _isLoading || _errorMessage != null
                      ? null
                      : (value) async {
                          await _audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_position),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                        Text(
                          _formatTime(_duration),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
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
                color: Colors.grey,
                fontSize: 14.0,
              ),
            ),
          ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14.0,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildAudioComingSoon() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Recitation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        Text(
          'Audio recitation coming soon for this verse.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14.0,
          ),
        ),
      ],
    );
  }
}


