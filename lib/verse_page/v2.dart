import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class GitaVersePage extends StatefulWidget {
  @override
  _GitaVersePageState createState() => _GitaVersePageState();
}

class _GitaVersePageState extends State<GitaVersePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  void _playAudio() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource('https://bhagavadgitaclass.com/wp-content/audio/01/01/BG_01_01-03_-_Bhakti_Vikas_Swami.mp3'));
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verse 2.13', style: TextStyle(color: Colors.white)),
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
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  children: [
                    _wordWithMeaning('देहिनः', 'of the embodied'),
                    _wordWithMeaning('अस्मिन', 'in this'),
                    _wordWithMeaning('यथा', 'as'),
                    _wordWithMeaning('देहे', 'in the body'),
                    _wordWithMeaning('कौमारं', 'boyhood'),
                    _wordWithMeaning('यौवनं', 'youth'),
                    _wordWithMeaning('जरा', 'old age'),
                    TextSpan(text: '\n'), // Line break
                    _wordWithMeaning('तथा', 'similarly'),
                    _wordWithMeaning('देहान्तर', 'of transference of the body'),
                    _wordWithMeaning('प्राप्तिः', 'achievement'),
                    TextSpan(text: '\n'), // Line break
                    _wordWithMeaning('धीऱः', 'the sober'),
                    _wordWithMeaning('तत्र', 'thereupon'),
                    _wordWithMeaning('न', 'never'),
                    _wordWithMeaning('मुह्यति', 'is deluded'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'dehino ’smin yathā dehe\nkaumāraṁ yauvanaṁ jarā\ntathā dehāntara-prāptir\ndhīras tatra na muhyati',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              IconButton(
                onPressed: _playAudio,
                icon: Icon(
                  isPlaying ? Icons.volume_up : Icons.volume_off,
                  color: Colors.deepPurpleAccent,
                  size: 30.0,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Translation:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'As the embodied soul continuously passes, in this body, from boyhood to youth to old age, the soul similarly passes into another body at death. A sober person is not bewildered by such a change.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _wordWithMeaning(String word, String meaning) {
    return TextSpan(
      children: [
        TextSpan(
          text: '$word\n',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        TextSpan(
          text: meaning + ' ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
