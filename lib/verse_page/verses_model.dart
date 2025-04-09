import 'dart:convert';
import 'package:flutter/foundation.dart';

class Verse {
  final int id1;
  final int id2;
  final String textSanskrit1;
  final String textSanskrit2;
  final String line1;
  final String line2;
  final String line3;
  final String line4;
  final String textSynonyms;
  final String textTranslation;
  final String textPurport;
  final List<String> slines;
  final List<String> audioFiles;

  Verse({
    required this.id1,
    required this.id2,
    required this.textSanskrit1,
    required this.textSanskrit2,
    required this.textSynonyms,
    required this.textTranslation,
    required this.textPurport,
    required this.line1,
    required this.line2,
    required this.line3,
    required this.line4,
    required this.slines,
    required this.audioFiles,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id1: json['id1'],
      id2: json['id2'],
      textSanskrit1: json['textSanskrit1'],
      textSanskrit2: json['textSanskrit2'],
      textSynonyms: json['textSynonyms'],
      textTranslation: json['textTranslation'],
      textPurport: json['textPurport'],
      line1: json['line1'],
      line2: json['line2'],
      line3: json['line3'],
      line4: json['line4'],
      slines: [
        json['sline1'] ?? '',
        json['sline2'] ?? '',
        json['sline3'] ?? '',
        json['sline4'] ?? '',
      ],
      audioFiles: List<String>.from(json['audioFiles'] ?? []),
    );
  }

  static List<Verse> fromJsonList(String jsonString) {
    try {
      final data = json.decode(jsonString);
      if (data is! Map || data['verses'] is! List) {
        throw FormatException("Invalid JSON format");
      }
      return (data['verses'] as List).map((e) => Verse.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error parsing JSON: $e");
      return [];
    }
  }
}

