import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class GitaVersePage extends StatefulWidget {
  const GitaVersePage({super.key});

  @override
  _GitaVersePageState createState() => _GitaVersePageState();
}

class _GitaVersePageState extends State<GitaVersePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _fontSize = 14.0; // Default font size

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
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verse 2.13', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showFontSettingsDialog(context),
          ),
        ],
      ),
      body: isLandscape ? _buildLandscapeLayout(screenSize) : _buildPortraitLayout(),
    );
  }

  void _showFontSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Font Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Adjust font size for all elements:'),
              Slider(
                value: _fontSize,
                min: 10.0,
                max: 30.0,
                divisions: 20,
                label: '$_fontSize',
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortraitLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLine([
              {"sanskrit": "dehinaḥ", "translation": "of the embodied"},
              {"sanskrit": "asmin", "translation": "in this"},
              {"sanskrit": "yathā", "translation": "as"},
              {"sanskrit": "dehe", "translation": "in the body"},
            ]),
            _buildLine([
              {"sanskrit": "kaumāram", "translation": "boyhood"},
              {"sanskrit": "yauvanam", "translation": "youth"},
              {"sanskrit": "jarā", "translation": "old age"},
            ]),
            _buildLine([
              {"sanskrit": "tathā", "translation": "similarly"},
              {"sanskrit": "deha-antara", "translation": "of transference of the body"},
              {"sanskrit": "prāptiḥ", "translation": "achievement"},
            ]),
            _buildLine([
              {"sanskrit": "dhīraḥ", "translation": "the sober"},
              {"sanskrit": "tatra", "translation": "thereupon"},
              {"sanskrit": "na", "translation": "never"},
              {"sanskrit": "muhyati", "translation": "is deluded"}
            ]),

            Text(
              'देहिनोऽस्मिन्यथा देहे\nकौमारं यौवनं जरा ।\nतथा देहान्तरप्राप्तिर्धीरस्तत्र\nन मुह्यति ॥ १३ ॥',
              style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
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
              'dehinaḥ — of the embodied; asmin — in this; yathā — as; dehe — in the body; kaumāram — boyhood; yauvanam — youth; jarā — old age; tathā — similarly; deha-antara — of transference of the body; prāptiḥ — achievement; dhīraḥ — the sober; tatra — thereupon; na — never; muhyati — is deluded.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            Text(
              'Translation:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'As the embodied soul continuously passes, in this body, from boyhood to youth to old age, the soul similarly passes into another body at death. A sober person is not bewildered by such a change.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            Text(
              'Purport:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Since every living entity is an individual soul, each is changing his body every moment, manifesting sometimes as a child, sometimes as a youth and sometimes as an old man. Yet the same spirit soul is there and does not undergo any change. This individual soul finally changes the body at death and transmigrates to another body; and since it is sure to have another body in the next birth – either material or spiritual – there was no cause for lamentation by Arjuna on account of death, neither for Bhīṣma nor for Droṇa, for whom he was so much concerned. Rather, he should rejoice for their changing bodies from old to new ones, thereby rejuvenating their energy. Such changes of body account for varieties of enjoyment or suffering, according to one’s work in life. So Bhīṣma and Droṇa, being noble souls, were surely going to have spiritual bodies in the next life, or at least life in heavenly bodies for superior enjoyment of material existence. So, in either case, there was no cause of lamentation.Any man who has perfect knowledge of the constitution of the individual soul, the Supersoul, and nature – both material and spiritual – is called a dhīra, or a most sober man. Such a man is never deluded by the change of bodies.The Māyāvādī theory of oneness of the spirit soul cannot be entertained, on the ground that the spirit soul cannot be cut into pieces as a fragmental portion. Such cutting into different individual souls would make the Supreme cleavable or changeable, against the principle of the Supreme Soul’s being unchangeable. As confirmed in the Gītā, the fragmental portions of the Supreme exist eternally (sanātana) and are called kṣara; that is, they have a tendency to fall down into material nature. These fragmental portions are eternally so, and even after liberation the individual soul remains the same – fragmental. But once liberated, he lives an eternal life in bliss and knowledge with the Personality of Godhead. The theory of reflection can be applied to the Supersoul, who is present in each and every individual body and is known as the Paramātmā. He is different from the individual living entity. When the sky is reflected in water, the reflections represent both the sun and the moon and the stars also. The stars can be compared to the living entities and the sun or the moon to the Supreme Lord. The individual fragmental spirit soul is represented by Arjuna, and the Supreme Soul is the Personality of Godhead Śrī Kṛṣṇa. They are not on the same level, as it will be apparent in the beginning of the Fourth Chapter. If Arjuna is on the same level with Kṛṣṇa, and Kṛṣṇa is not superior to Arjuna, then their relationship of instructor and instructed becomes meaningless. If both of them are deluded by the illusory energy (māyā), then there is no need of one being the instructor and the other the instructed. Such instruction would be useless because, in the clutches of māyā, no one can be an authoritative instructor. Under the circumstances, it is admitted that Lord Kṛṣṇa is the Supreme Lord, superior in position to the living entity, Arjuna, who is a forgetful soul deluded by māyā. ',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(Size screenSize) {
    return Row(
      children: [
        Container(
          width: screenSize.width * 0.5,
          child: Center(
            child: Text('Left Panel - Landscape Layout'),
          ),
        ),
        Container(
          width: screenSize.width * 0.5,
          child: Center(
            child: Text('Right Panel - Landscape Layout'),
          ),
        ),
      ],
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
