import 'dart:convert';
import 'package:flutter/foundation.dart';

class Verse {
  final int id;
  final String textSanskrit;
  final String textSynonyms;
  final String textTranslation;
  final String textPurport;
  final List<String> lines;

  Verse({
    required this.id,
    required this.textSanskrit,
    required this.textSynonyms,
    required this.textTranslation,
    required this.textPurport,
    required this.lines,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'],
      textSanskrit: json['textSanskrit'],
      textSynonyms: json['textSynonyms'],
      textTranslation: json['textTranslation'],
      textPurport: json['textPurport'],
      lines: [
        json['line1'] ?? '',
        json['line2'] ?? '',
        json['line3'] ?? '',
        json['line4'] ?? '',
      ],
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

