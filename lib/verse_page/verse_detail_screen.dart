import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';

class GitaVersePage extends StatefulWidget {
  final Verse_1 verse;
  const GitaVersePage({super.key, required this.verse});

  @override
  State<GitaVersePage> createState() => _GitaVersePageState();
}

class _GitaVersePageState extends State<GitaVersePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late String _selectedAudio;
  late Map<String, String> _audioFiles;
  Set<String> _selectedViews = {};


  // For tooltip display
  bool _tooltipVisible = false;
  String _tooltipText = '';
  Offset _tooltipPosition = Offset.zero;
  bool _tooltipLocked = false;
  
  // For content visibility
  bool _showSanskrit = true;
  bool _showEnglish = true;
  bool _showWordMeanings = false;
  bool _showTranslation = true;
  bool _showPurport = false;

  // For view selection
  final List<String> _viewOptions = [
    'All',
    'Sanskrit',
    'English',
    'Word Meanings',
    'Translation',
    'Purport',
  ];
  String _selectedView = 'All';

  @override
  void initState() {
    super.initState();
    
    // Set up audio files
    if (widget.verse.audioPaths.isNotEmpty) {
      _audioFiles = {
        for (int i = 0; i < widget.verse.audioPaths.length; i++)
          'Audio ${i + 1}': widget.verse.audioPaths[i],
      };

      _selectedAudio = _audioFiles.keys.first;
      _audioPlayer.setSource(AssetSource(_audioFiles[_selectedAudio]!));

      _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
      _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
      _audioPlayer.onPlayerComplete.listen((_) => setState(() {
        isPlaying = false;
        _position = Duration.zero;
      }));
    } else {
      _audioFiles = {};
    }
  }

  void _setAudioSource() {
    if (_audioFiles.isNotEmpty && _audioFiles[_selectedAudio] != null) {
      _audioPlayer.setSource(AssetSource(_audioFiles[_selectedAudio]!));
    }
  }

  void _playAudio() async {
    if (_audioFiles.isEmpty) return;
    
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() => isPlaying = !isPlaying);
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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

  // Update visibility based on selected view
  void _updateVisibility(String view) {
    setState(() {
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Bhagavad Gita ${widget.verse.chapter}.${widget.verse.shloka}',
            style: const TextStyle(color: Color(0xFFFF9933)),
          ),
          backgroundColor: Color(0xFF2C2C54),
          iconTheme: const IconThemeData(color: Color(0xFFFF9933)),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breadcrumb navigation
                        _buildBreadcrumb(),
                        
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C2C54),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark_add_outlined),
                                      color: Color(0xFF2C2C54),
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
                              
                              // Card body - dynamic content based on selected view
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sanskrit (Devanagari) section
                                    if (_showSanskrit && widget.verse.sanskrit.isNotEmpty) 
                                      _buildVerseSection(
                                        'Sanskrit (Devanagari)', 
                                        widget.verse.sanskrit,
                                        false, // Not interactive
                                        _selectedView == 'Sanskrit', // Larger text for Sanskrit-only view
                                      ),
                                    
                                    if (_showSanskrit && _showEnglish)
                                      const SizedBox(height: 24.0),
                                    
                                    // Transliteration section with interactive words
                                    if (_showEnglish && widget.verse.english.isNotEmpty) 
                                      _buildVerseSection(
                                        'Transliteration (IAST)', 
                                        widget.verse.english,
                                        true, // Interactive for hover tooltips
                                        _selectedView == 'English', // Larger text for English-only view
                                      ),
                                    
                                    if (_showWordMeanings || _showTranslation || _showPurport)
                                      const SizedBox(height: 16.0),
                                    
                                    // Word Meanings section
                                    if (_showWordMeanings)
                                      _buildExpandedSection(
                                        'Word-by-Word Translation',
                                        _buildWordMeanings(_selectedView == 'Word Meanings'),
                                      ),
                                    
                                    if (_showWordMeanings && (_showTranslation || _showPurport))
                                      const SizedBox(height: 16.0),
                                    
                                    // Translation section
                                    if (_showTranslation)
                                      _buildExpandedSection(
                                        'Translation',
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            widget.verse.translation,
                                            style: TextStyle(
                                              fontSize: _selectedView == 'Translation' ? 18 : 16, 
                                              height: 1.6
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                      ),
                                    
                                    if (_showTranslation && _showPurport)
                                      const SizedBox(height: 16.0),
                                    
                                    // Purport section
                                    if (_showPurport)
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
                              if (widget.verse.audioPaths.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF8E1),
                                    border: Border(
                                      top: BorderSide(
                                        color: Color(0xFFE9ECEF),
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  child: _buildAudioPlayerControls(),
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

  Widget _buildViewOption(String view) {
    final isSelected = _selectedViews.contains(view);

    return GestureDetector(
      onTap: () {
        _updateVisibility(view);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C54) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF2C2C54) : Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          view,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF9933) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }


  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        children: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Scriptures', style: TextStyle(color: Color(0xFF2C2C54))),
          ),
          const Text(' / ', style: TextStyle(color: Color(0xFF2C2C54))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Bhagavad Gita', style: TextStyle(color: Color(0xFF2C2C54))),
          ),
          const Text(' / ', style: TextStyle(color: Color(0xFF2C2C54))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Chapter ${widget.verse.chapter}', style: TextStyle(color: Color(0xFF2C2C54))),
          ),
          const Text(' / ', style: TextStyle(color: Color(0xFF2C2C54))),
          Text(
            'Verse ${widget.verse.shloka}',
            style: const TextStyle(color: Color(0xFF2C2C54), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseSection(String title, String content, bool interactive, bool isFullView) {
    final lines = content.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isFullView ? 22 : 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C54),
          ),
          textAlign: TextAlign.center,
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
                return _buildInteractiveLine(line, isFullView);
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: isFullView ? 24 : 18, 
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

  Widget _buildInteractiveLine(String line, bool isFullView) {
    final words = line.split(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4.0,
        runSpacing: 4.0,
        children: words.map((word) {
          String? meaning;
          for (var entry in widget.verse.synonyms.entries) {
            if (word.toLowerCase().contains(entry.key.toLowerCase()) ||
                entry.key.toLowerCase().contains(word.toLowerCase())) {
              meaning = entry.value.meaning;
              break;
            }
          }

          return GestureDetector(
            onTapDown: (details) {
              if (meaning != null) {
                final Offset position = details.globalPosition;
                _showTooltip('$word: $meaning', Offset(position.dx, position.dy + 20));
              }
            },
            onTap: () {
              if (meaning != null) {
                _toggleTooltipLock();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
              decoration: BoxDecoration(
                border: meaning != null
                    ? const Border(bottom: BorderSide(color: Color(0xFF2C2C54), width: 1.0))
                    : null,
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: isFullView ? 22 : 18,
                  color: meaning != null ? Color(0xFF2C2C54) : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
                  style: TextStyle(
                    fontSize: _selectedView == title.split(' ')[0] ? 22 : 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedView == title.split(' ')[0] ? 
                      Color(0xFF2C2C54) : Colors.black87,
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

  Widget _buildWordMeanings([bool isFullView = false]) {
    if (widget.verse.synonyms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Word-by-word meanings are not available for this verse.'),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isFullView ? 0.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.verse.synonyms.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isFullView ? Colors.grey.shade50 : null,
              borderRadius: isFullView ? BorderRadius.circular(8.0) : null,
              border: isFullView ? Border.all(color: Colors.grey.shade200) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isFullView ? 18 : 16,
                    color: Color(0xFF2C2C54),
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Word: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isFullView ? 16 : 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.versetext,
                        style: TextStyle(
                          fontSize: isFullView ? 16 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Meaning: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isFullView ? 16 : 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.meaning,
                        style: TextStyle(
                          fontSize: isFullView ? 16 : 14,
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
  
  Widget _buildAudioPlayerControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio Recitation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C54),
          ),
        ),
        const SizedBox(height: 16.0),
        
        // Audio player controls
        Row(
          children: [
            IconButton(
              onPressed: _playAudio,
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Color(0xFF2C2C54),
                size: 40.0,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatTime(_position), style: TextStyle(color: Color(0xFF2C2C54))),
                        Text(_formatTime(_duration), style: TextStyle(color: Color(0xFF2C2C54))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        if (_audioFiles.length > 1) ...[
          const SizedBox(height: 16.0),
          DropdownButton<String>(
            value: _selectedAudio,
            isExpanded: true,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedAudio = newValue;
                  _setAudioSource();
                });
              }
            },
            items: _audioFiles.keys.map((audio) {
              return DropdownMenuItem<String>(
                value: audio,
                child: Text(audio),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}


