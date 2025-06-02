import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

enum AudioPlayType { line, fullVerse, word }

class AudioPlayerWidget extends StatefulWidget {
  final String chapter;
  final String shloka;
  final String audioAssetPath;
  final String verseText;

  const AudioPlayerWidget({
    super.key,
    required this.chapter,
    required this.shloka,
    required this.audioAssetPath,
    required this.verseText,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  AudioPlayType _playType = AudioPlayType.line;
  int _repetitions = 2;
  bool _isPlaying = false;
  int _currentSegmentIndex = 0;
  int _currentRepetition = 0;
  List<Map<String, dynamic>> _segments = [];
  String? _currentLabel;
  bool _isLoading = true;
  bool _isStopped = false;
  bool _audioAvailable = true;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _audioDuration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _audioPosition = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        // The state change might trigger updates for position/duration
        // through other listeners, so we don't need to update them here
      });
    });
    _loadSegments();
  }


  double _playbackRate = 1.0;
  bool _useLinearScale = false;

  List<double> get _speedOptions => _useLinearScale
      ? List.generate((4 - 1) ~/ 0.2 + 1, (i) => 1.0 + (i * 0.2))
      : [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  Duration get _displayedAudioDuration => _audioDuration == Duration.zero
      ? Duration.zero
      : Duration(milliseconds: (_audioDuration.inMilliseconds / _playbackRate).round());
  Duration get _displayedAudioPosition => _audioPosition == Duration.zero
      ? Duration.zero
      : Duration(milliseconds: (_audioPosition.inMilliseconds / _playbackRate).round());

  Future<void> _loadSegments() async {
    setState(() => _isLoading = true);
    try {
      final jsonStr = await rootBundle.loadString('assets/audio_mappings.json');
      final List<dynamic> mappings = json.decode(jsonStr);
      final mapping = mappings.firstWhere(
        (m) => m['chapter'] == widget.chapter && m['shloka'] == widget.shloka,
        orElse: () => null,
      );
      // Use full asset path for existence check
      String audioAssetPath = 'assets/Audio/Bhagavad_gita_${widget.chapter}.${widget.shloka}.mp3';
      bool audioExists = await _audioFileExists(audioAssetPath);
      debugPrint('Audio file exists: $audioExists at path: $audioAssetPath');
      if (mapping != null) {
        setState(() {
          _segments = List<Map<String, dynamic>>.from(mapping['segments']);
          _isLoading = false;
          _audioAvailable = audioExists;
        });
      } else {
        setState(() {
          _segments = [];
          _isLoading = false;
          _audioAvailable = audioExists;
        });
      }
    } catch (e) {
      setState(() {
        _segments = [];
        _isLoading = false;
        _audioAvailable = false;
      });
    }
  }

  Future<bool> _audioFileExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }


  List<Map<String, dynamic>> get _filteredSegments {
    switch (_playType) {
      case AudioPlayType.fullVerse:
        // Find the full segment or merge all lines if not present
        final full = _segments.where((s) => s['tag'] == 'full').toList();
        if (full.isNotEmpty) return full;
        // If no full tag, merge all lines
        if (_segments.any((s) => s['tag'] == 'line')) {
          final first = _segments.firstWhere((s) => s['tag'] == 'line');
          final last = _segments.lastWhere((s) => s['tag'] == 'line');
          return [
            {
              'start': first['start'],
              'end': last['end'],
              'label': widget.verseText.replaceAll('\n', ' '),
              'tag': 'full',
            }
          ];
        }
        return [];
      case AudioPlayType.line:
        return _segments.where((s) => s['tag'] == 'line').toList();
      case AudioPlayType.word:
        final wordSegments = _segments.where((s) => s['tag'] == 'word').toList();
        if (wordSegments.isEmpty) {
          // Show coming soon if word-by-word is not available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _playType == AudioPlayType.word) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon: Word-by-word audio not available for this verse')),
              );
              if (!mounted) return;
              setState(() {
                _playType = AudioPlayType.line;
              });
            }
          });
        }
        return wordSegments;
    }
  }

  Future<void> _play() async {
    final segments = _filteredSegments;
    // Use full asset path for existence check
    String audioAssetPath = 'assets/Audio/Bhagavad_gita_${widget.chapter}.${widget.shloka}.mp3';
    // Use relative path for AssetSource
    String audioSourcePath = 'assets/Audio/Bhagavad_gita_${widget.chapter}.${widget.shloka}.mp3';
    if (_playType == AudioPlayType.word && segments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon: Word-by-word audio not available for this verse')),
      );
      setState(() {
        _isPlaying = false;
        _currentLabel = null;
      });
      return;
    }
    if (!await _audioFileExists(audioAssetPath)) {
      setState(() {
        _isPlaying = false;
        _currentLabel = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon: Audio not available for this verse')),
      );
      return;
    }
    setState(() {
      _isPlaying = true;
      _isStopped = false;
      _currentSegmentIndex = 0;
      _currentRepetition = 0;
    });
    await _audioPlayer.setPlaybackRate(_playbackRate);
    if (segments.isEmpty) {
      await _audioPlayer.play(
        AssetSource(audioSourcePath),
        volume: 1.0,
        position: Duration.zero,
      );
      _audioPlayer.onPlayerComplete.listen((event) {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
          _currentLabel = null;
        });
      });
    } else {
      await _playSegmentsSequentially(audioSourcePath, segments);
    }
  }

  Future<void> _playSegmentsSequentially(String audioSourcePath, List<Map<String, dynamic>> segments) async {
    for (_currentSegmentIndex = 0; _currentSegmentIndex < segments.length; _currentSegmentIndex++) {
      if (_isStopped) break;
      final segment = segments[_currentSegmentIndex];
      setState(() {
        _currentLabel = segment['label'];
      });
      for (_currentRepetition = 0; _currentRepetition < _repetitions; _currentRepetition++) {
        if (_isStopped) return;
        await _audioPlayer.setPlaybackRate(_playbackRate);
        await _audioPlayer.play(
          AssetSource(audioSourcePath),
          position: Duration(milliseconds: segment['start']),
        );
        int segmentDuration = ((segment['end'] - segment['start']) / _playbackRate).round();
        await Future.delayed(Duration(milliseconds: segmentDuration));
        await _audioPlayer.stop();
        if (_currentRepetition <= _repetitions - 1) {
          await Future.delayed(Duration(milliseconds: segmentDuration));
        }
      }
    }
    setState(() {
      _isPlaying = false;
      _currentLabel = null;
    });
  }

  void _pause() {
    _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _stop() {
    _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _isStopped = true;
      _currentLabel = null;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  
    if (_audioAvailable == false && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Audio not available for this verse',
          style: TextStyle(color: theme.colorScheme.error, fontStyle: FontStyle.italic),
        ),
      );
    }
    if (_audioAvailable == true && _segments.isEmpty && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                 
              child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                    'Now Playing: ${widget.chapter}.${widget.shloka}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
              const SizedBox(height: 16),
              
              Slider(
                min: 0,
                max: _displayedAudioDuration.inMilliseconds.toDouble(), 
                value: _displayedAudioPosition.inMilliseconds.clamp(0, _displayedAudioDuration.inMilliseconds).toDouble(),
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
                onChanged: (value) async {
                  final pos = Duration(milliseconds: (value * _playbackRate).toInt());
                  await _audioPlayer.seek(pos);
                },
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_displayedAudioPosition),
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_displayedAudioDuration),
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pause' : 'Play'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isPlaying ? _pause : _play,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _stop,
                  ),
                ],
              )
    
          ],
        )
      ),
      );
    }
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Controls section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // First row of controls
                  Row(
                    children: [
                      Icon(Icons.music_note, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Mode:', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<AudioPlayType>(
                          isExpanded: true,
                          value: _playType,
                          borderRadius: BorderRadius.circular(12),
                          underline: Container(height: 1, color: theme.colorScheme.primary.withOpacity(0.5)),
                          items: const [
                            DropdownMenuItem(
                              value: AudioPlayType.line,
                              child: Text('Line by Line'),
                            ),
                            DropdownMenuItem(
                              value: AudioPlayType.fullVerse,
                              child: Text('Full Verse'),
                            ),
                            DropdownMenuItem(
                              value: AudioPlayType.word,
                              child: Text('Word by Word'),
                            ),
                          ],
                          onChanged: _isPlaying ? null : (val) {
                            if (val != null) setState(() => _playType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  

                  // Replace the second row of controls (Row) with a Wrap for better responsiveness
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 4),
                          Text('Repeat:', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 60,
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _repetitions,
                              underline: Container(height: 1, color: theme.colorScheme.primary.withOpacity(0.5)),
                              items: List.generate(5, (i) => i + 1)
                                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                                  .toList(),
                              onChanged: _isPlaying ? null : (val) {
                                if (val != null) setState(() => _repetitions = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 4),
                          Text('Speed:', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 80,
                            child: DropdownButton<double>(
                              isExpanded: true,
                              value: _playbackRate,
                              underline: Container(height: 1, color: theme.colorScheme.primary.withOpacity(0.5)),
                              items: _speedOptions
                                  .map((speed) => DropdownMenuItem(
                                        value: speed,
                                        child: Text('${speed}x'),
                                      ))
                                  .toList(),
                              onChanged: _isPlaying ? null : (val) async {
                                if (val != null) {
                                  setState(() {
                                    _playbackRate = val;
                                  });
                                  await _audioPlayer.setPlaybackRate(_playbackRate);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 4),
                          Text('Scale:', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 80,
                            child: DropdownButton<bool>(
                              isExpanded: true,
                              value: _useLinearScale,
                              underline: Container(height: 1, color: theme.colorScheme.primary.withOpacity(0.5)),
                              items: const [
                                DropdownMenuItem(value: false, child: Text('Simple')),
                                DropdownMenuItem(value: true, child: Text('Linear')),
                              ],
                              onChanged: _isPlaying ? null : (val) {
                                if (val != null) {
                                  setState(() {
                                    _useLinearScale = val;
                                    if (!_speedOptions.contains(_playbackRate)) {
                                      _playbackRate = 1.0;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                  ),
              
              ),
            // Player section
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!_audioAvailable)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Text(
                  'Audio coming soon',
                  style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              )
            else ...[
              if (_currentLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Now Playing: $_currentLabel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              Slider(
                min: 0,
                max: _displayedAudioDuration.inMilliseconds.toDouble(),
                value: _displayedAudioPosition.inMilliseconds.clamp(0, _displayedAudioDuration.inMilliseconds).toDouble(),
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
                onChanged: (value) async {
                  final pos = Duration(milliseconds: (value * _playbackRate).toInt());
                  await _audioPlayer.seek(pos);
                },
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_displayedAudioPosition),
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_displayedAudioDuration),
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pause' : 'Play'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isPlaying ? _pause : _play,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _stop,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}





  
String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));
  return '$minutes:$seconds';
}
