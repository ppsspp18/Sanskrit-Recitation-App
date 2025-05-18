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
  final List<String> audioPaths; // New field for audio paths
  final String verseId; // Unique ID for the verse (chapter-shloka)

  Verse_1({
    required this.chapter,
    required this.shloka,
    required this.sanskrit,
    required this.english,
    required this.synonyms,
    required this.translation,
    required this.purport,
    this.audioPaths = const [], // Default empty list for audio paths
    String? verseId,
  }) : verseId = verseId ?? "${chapter.padLeft(2, '0')}-${shloka.padLeft(2, '0')}";

  factory Verse_1.fromJson(Map<String, dynamic> json) {
    final syns = <String, Synonym>{};
    if (json['synonyms'] != null) {
      json['synonyms'].forEach((k, v) {
        syns[k] = Synonym.fromJson(v);
      });
    }

    return Verse_1(
      chapter: json['chapter'] ?? '',
      shloka: json['shloka'] ?? '',
      sanskrit: json['sanskrit'] ?? '',
      english: json['english'] ?? '',
      synonyms: syns,
      translation: json['translation'] ?? '',
      purport: json['purport'] ?? '',
      audioPaths: json['audioPaths']?.cast<String>() ?? [],
      verseId: json['verseId'],
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
      'audioPaths': audioPaths,
      'verseId': verseId,
    };
  }
}
