import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';

class GitaVersePage extends StatefulWidget {
  final Verse verse;
  const GitaVersePage({super.key, required this.verse});

  @override
  _GitaVersePageState createState() => _GitaVersePageState();
}

class _GitaVersePageState extends State<GitaVersePage> {

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSource(AssetSource('v1.mp3'));
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  void _playAudio() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verse ${widget.verse.id}', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var line in widget.verse.lines) _buildLine(parseLine(line)),

              Text(
                widget.verse.textSanskrit,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              SizedBox(height: 10),
              IconButton(
                onPressed: _playAudio,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.deepPurpleAccent,
                  size: 40.0,
                ),
              ),
              Slider(
                min: 0,
                max: _duration.inSeconds.toDouble(),
                value: _position.inSeconds.toDouble(),
                onChanged: (value) async {
                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
                activeColor: Colors.deepPurpleAccent,
                inactiveColor: Colors.grey,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTime(_position)),
                  Text(_formatTime(_duration)),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Synonyms:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.verse.textSynonyms,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Text(
                'Translation:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.verse.textTranslation,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Text(
                'Purport:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.verse.textPurport,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget _buildLine(List<Map<String, String>> phrases, {bool skipLine = true}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 4.0,
        children: phrases.map((phrase) {
          return Column(
            children: [
              Text(
                phrase['sanskrit']!,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                phrase['translation']!,
                style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }).toList(),
      ),
      if (skipLine) SizedBox(height: 12.0),
    ],
  );
}

List<Map<String, String>> parseLine(String line) {
  List<Map<String, String>> result = [];
  List<String> words = line.split(';');

  for (String word in words) {
    List<String> parts = word.split('—');
    if (parts.length == 2) {
      result.add({"sanskrit": parts[0].trim(), "translation": parts[1].trim()});
    }
  }
  return result;
}