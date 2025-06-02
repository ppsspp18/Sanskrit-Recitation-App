class AudioSegment {
  final int start;
  final int end;
  final String label;
  final String tag;

  AudioSegment({
    required this.start,
    required this.end,
    required this.label,
    required this.tag,
  });

  factory AudioSegment.fromJson(Map<String, dynamic> json) {
    return AudioSegment(
      start: json['start'] ?? 0,
      end: json['end'] ?? 0,
      label: json['label'] ?? '',
      tag: json['tag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'label': label,
      'tag': tag,
    };
  }
}

class Synonym {
  final String versetext;
  final String meaning;

  Synonym({required this.versetext, required this.meaning});

  factory Synonym.fromJson(Map<String, dynamic> json) {
    return Synonym(
      versetext: json['versetext'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }
}

class Verse_1 {
  final String chapter;
  final String shloka;
  final String sanskrit;
  final String english;
  final Map<String, Synonym> synonyms;
  final String translation;
  final String purport;
  final String? audioPath; // Changed to a single path with nullable type
  final List<AudioSegment>? segments; // Added segments with nullable type
  final String verseId;

  Verse_1({
    required this.chapter,
    required this.shloka,
    required this.sanskrit,
    required this.english,
    required this.synonyms,
    required this.translation,
    required this.purport,
    this.audioPath, // Now nullable
    this.segments, // New field for segments
    String? verseId,
  }) : verseId = verseId ?? "${chapter.padLeft(2, '0')}-${shloka.padLeft(2, '0')}";

  factory Verse_1.fromJson(Map<String, dynamic> json) {
    final syns = <String, Synonym>{};
    if (json['synonyms'] != null) {
      json['synonyms'].forEach((k, v) {
        syns[k] = Synonym.fromJson(v);
      });
    }

    // Handle segments if available
    List<AudioSegment>? segmentsList;
    if (json['segments'] != null) {
      segmentsList = (json['segments'] as List)
          .map((segment) => AudioSegment.fromJson(segment))
          .toList();
    }

    return Verse_1(
      chapter: json['chapter'] ?? '',
      shloka: json['shloka'] ?? '',
      sanskrit: json['sanskrit'] ?? '',
      english: json['english'] ?? '',
      synonyms: syns,
      translation: json['translation'] ?? '',
      purport: json['purport'] ?? '',
      audioPath: "assets/Audio/Bhagavad_gita_${json['chapter']}.${json['shloka']}.mp3",
      segments: segmentsList,
      verseId: json['verseId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter': chapter,
      'shloka': shloka,
      'sanskrit': sanskrit,
      'english': english,
      'synonyms': synonyms.map((key, value) => MapEntry(key, {
        'versetext': value.versetext,
        'meaning': value.meaning,
      })),
      'translation': translation,
      'purport': purport,
      'audioPath': audioPath,
      'segments': segments?.map((segment) => segment.toJson()).toList(),
      'verseId': verseId,
    };
  }
}
