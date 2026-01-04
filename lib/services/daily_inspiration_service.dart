import 'dart:convert';

import 'package:flutter/services.dart';

class DailyInspirationItem {
  final String arabic;
  final String en;
  final String fr;
  final String source;
  final String type;

  const DailyInspirationItem({
    required this.arabic,
    required this.en,
    required this.fr,
    required this.source,
    required this.type,
  });
}

class DailyInspirationSet {
  final DailyInspirationItem verse;
  final DailyInspirationItem hadith;
  final DailyInspirationItem value;

  const DailyInspirationSet({
    required this.verse,
    required this.hadith,
    required this.value,
  });
}

class DailyInspirationService {
  static const String _assetPath = 'assets/data/daily_inspirations.json';

  Future<DailyInspirationSet> loadToday() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final verses = (decoded['verses'] as List<dynamic>? ?? [])
        .map((item) => _fromMap(item, 'verse'))
        .toList();
    final hadiths = (decoded['hadiths'] as List<dynamic>? ?? [])
        .map((item) => _fromMap(item, 'hadith'))
        .toList();
    final values = (decoded['values'] as List<dynamic>? ?? [])
        .map((item) => _fromMap(item, 'value'))
        .toList();

    if (verses.isEmpty || hadiths.isEmpty || values.isEmpty) {
      throw StateError('Daily inspirations are missing.');
    }

    final index = _dayOfYear(DateTime.now());
    return DailyInspirationSet(
      verse: verses[index % verses.length],
      hadith: hadiths[index % hadiths.length],
      value: values[index % values.length],
    );
  }

  DailyInspirationItem _fromMap(dynamic data, String type) {
    final map = data as Map<String, dynamic>;
    return DailyInspirationItem(
      arabic: map['arabic']?.toString() ?? '',
      en: map['en']?.toString() ?? '',
      fr: map['fr']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      type: type,
    );
  }

  int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays;
  }
}
