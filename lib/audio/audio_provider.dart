import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class GlobalAudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentSource;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  String? _error;

  GlobalAudioProvider() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
    _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  String? get currentSource => _currentSource;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> setSource(String source) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _audioPlayer.setSource(AssetSource(source));
      _currentSource = source;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> play() async {
    if (_currentSource == null) return;
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void disposePlayer() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
