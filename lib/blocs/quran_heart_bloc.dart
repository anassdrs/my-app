import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:quran/quran.dart' as quran;

// --- Helper Models ---

class ParsedQuranHeartSvg {
  final List<QuranHeartSegment> segments;
  final List<QuranHeartLabel> labels;
  final Size viewBoxSize;
  final String rawSvg;
  final String svgPathsOnly;
  final String svgTextOnly;

  ParsedQuranHeartSvg({
    required this.segments,
    required this.labels,
    required this.viewBoxSize,
    required this.rawSvg,
    required this.svgPathsOnly,
    required this.svgTextOnly,
  });
}

class QuranHeartSegment {
  final int id;
  final int groupId;
  final String name;
  final Path path;
  final int? surahNumber;
  final Offset center;

  QuranHeartSegment({
    required this.id,
    required this.groupId,
    required this.name,
    required this.path,
    required this.surahNumber,
    required this.center,
  });
}

class QuranHeartLabel {
  final String text;
  final double x;
  final double y;
  final int groupId;

  QuranHeartLabel({
    required this.text,
    required this.x,
    required this.y,
    required this.groupId,
  });
}

// --- BLoC Events ---

abstract class QuranHeartEvent {}

class LoadQuranHeartEvent extends QuranHeartEvent {}

class ToggleQuranHeartSegmentEvent extends QuranHeartEvent {
  final int key; // surahNumber or -(groupId + 1)
  ToggleQuranHeartSegmentEvent(this.key);
}

// --- BLoC States ---

abstract class QuranHeartState {}

class QuranHeartInitial extends QuranHeartState {}

class QuranHeartLoading extends QuranHeartState {}

class QuranHeartLoaded extends QuranHeartState {
  final ParsedQuranHeartSvg data;
  final Set<int> activeSurahs;

  QuranHeartLoaded({required this.data, required this.activeSurahs});
}

class QuranHeartError extends QuranHeartState {
  final String message;
  QuranHeartError(this.message);
}

// --- BLoC ---

class QuranHeartBloc extends Bloc<QuranHeartEvent, QuranHeartState> {
  static const String _svgAssetPath = 'assets/heart.svg';
  static const String _pathsAssetPath = 'assets/heart_paths.json';

  QuranHeartBloc() : super(QuranHeartInitial()) {
    on<LoadQuranHeartEvent>(_onLoad);
    on<ToggleQuranHeartSegmentEvent>(_onToggleSegment);
  }

  Future<void> _onLoad(
    LoadQuranHeartEvent event,
    Emitter<QuranHeartState> emit,
  ) async {
    emit(QuranHeartLoading());
    try {
      final data = await _loadSvgWithLabels();
      emit(QuranHeartLoaded(data: data, activeSurahs: {}));
    } catch (e) {
      emit(QuranHeartError(e.toString()));
    }
  }

  void _onToggleSegment(
    ToggleQuranHeartSegmentEvent event,
    Emitter<QuranHeartState> emit,
  ) {
    if (state is QuranHeartLoaded) {
      final curr = state as QuranHeartLoaded;
      final newActive = Set<int>.from(curr.activeSurahs);
      if (newActive.contains(event.key)) {
        newActive.remove(event.key);
      } else {
        newActive.add(event.key);
      }
      final updatedSvgPathsOnly = _buildSvgPathsOnly(
        curr.data.rawSvg,
        newActive,
      );
      final updatedData = ParsedQuranHeartSvg(
        segments: curr.data.segments,
        labels: curr.data.labels,
        viewBoxSize: curr.data.viewBoxSize,
        rawSvg: curr.data.rawSvg,
        svgPathsOnly: updatedSvgPathsOnly,
        svgTextOnly: curr.data.svgTextOnly,
      );
      emit(QuranHeartLoaded(data: updatedData, activeSurahs: newActive));
    }
  }

  // --- Parsing Logic ---

  Future<ParsedQuranHeartSvg> _loadSvgWithLabels() async {
    final raw = await rootBundle.loadString(_svgAssetPath);

    final viewBoxMatch = RegExp(
      r'viewBox="0 0 (\d+) (\d+)"',
      caseSensitive: false,
    ).firstMatch(raw);
    final viewBoxSize = Size(
      double.tryParse(viewBoxMatch?.group(1) ?? '1000') ?? 1000.0,
      double.tryParse(viewBoxMatch?.group(2) ?? '1000') ?? 1000.0,
    );

    final List<QuranHeartSegment> segments = [];
    final List<QuranHeartLabel> labels = [];

    final surahNameToNumber = <String, int>{};
    for (var i = 1; i <= quran.totalSurahCount; i++) {
      surahNameToNumber[_normalizeArabic(quran.getSurahNameArabic(i))] = i;
    }

    final textPattern = RegExp(
      r'<text[^>]*x="([^"]+)"[^>]*y="([^"]+)"[^>]*>([^<]+)</text>',
      caseSensitive: false,
    );

    final pathsRaw = await rootBundle.loadString(_pathsAssetPath);
    final List<dynamic> pathGroups = jsonDecode(pathsRaw) as List<dynamic>;
    final pathDataById = _buildPathDataMap(raw);
    var segmentId = 0;
    for (final entry in pathGroups) {
      final groupId = entry['groupId'] as int;
      final label = (entry['label'] as String?)?.trim() ?? '';
      final surahNumber = _resolveSurahNumber(label, surahNameToNumber);
      final List<dynamic> paths = entry['paths'] as List<dynamic>;
      for (final pathValue in paths) {
        final pathToken = pathValue as String;
        final pathData = pathDataById[pathToken] ?? pathToken;
        final safePath = _tryParsePath(pathData);
        if (safePath == null) {
          continue;
        }
        segments.add(
          QuranHeartSegment(
            id: segmentId++,
            groupId: groupId,
            name: label,
            path: safePath,
            surahNumber: surahNumber,
            center: safePath.getBounds().center,
          ),
        );
      }
    }
    print('QuranHeart: segments from json=${segments.length}');

    var groupId = 0;
    final textMatches = textPattern.allMatches(raw);
    for (final textMatch in textMatches) {
      final text = (textMatch.group(3) ?? '').trim();
      final x = double.tryParse(textMatch.group(1) ?? '');
      final y = double.tryParse(textMatch.group(2) ?? '');
      if (x != null && y != null && text.isNotEmpty) {
        labels.add(QuranHeartLabel(text: text, x: x, y: y, groupId: groupId));
      }
      groupId++;
    }

    final svgPathsOnly = _buildSvgPathsOnly(raw, {});

    final svgTextOnly = raw
        .replaceAllMapped(RegExp(r'<path[^>]*>'), (_) => '')
        .replaceAllMapped(RegExp(r'<text([^>]*?)>'), (match) {
          final attrs = match.group(1) ?? '';
          if (attrs.contains('fill=')) return '<text$attrs>';
          return '<text$attrs fill="#000000">';
        });

    return ParsedQuranHeartSvg(
      segments: segments,
      labels: labels,
      viewBoxSize: viewBoxSize,
      rawSvg: raw,
      svgPathsOnly: svgPathsOnly,
      svgTextOnly: svgTextOnly,
    );
  }

  String _buildSvgPathsOnly(String raw, Set<int> activeSurahs) {
    final surahNameToNumber = <String, int>{};
    for (var i = 1; i <= quran.totalSurahCount; i++) {
      surahNameToNumber[_normalizeArabic(quran.getSurahNameArabic(i))] = i;
    }

    final groupPattern = RegExp(
      r'(<g[^>]*class="section-group"[^>]*>)([\s\S]*?)(</g>)',
      caseSensitive: false,
    );
    final textPattern = RegExp(
      r'<text[^>]*x="([^"]+)"[^>]*y="([^"]+)"[^>]*>([^<]+)</text>',
      caseSensitive: false,
    );
    final pathPattern = RegExp(r'<path([^>]*?)>');

    var groupId = 0;
    var result = raw.replaceAllMapped(groupPattern, (match) {
      final open = match.group(1) ?? '';
      var body = match.group(2) ?? '';
      final close = match.group(3) ?? '';

      final textMatch = textPattern.firstMatch(body);
      final text = (textMatch?.group(3) ?? '').trim();
      final surahNumber = _resolveSurahNumber(text, surahNameToNumber);
      final key = surahNumber ?? -(groupId + 1);
      final isActive = activeSurahs.contains(key);
      final fill = isActive ? '#38BDF8' : '#ffffff';

      body = body.replaceAllMapped(textPattern, (_) => '');
      body = body.replaceAllMapped(pathPattern, (pathMatch) {
        final attrs = pathMatch.group(1) ?? '';
        final full = pathMatch.group(0) ?? '';
        if (full.contains(' fill=')) {
          return full.replaceAll(RegExp(r'fill="[^"]*"'), 'fill="$fill"');
        }
        return '<path$attrs fill="$fill">';
      });

      groupId++;
      return '$open$body$close';
    });

    result = result.replaceAllMapped(
      RegExp(r'<text[^>]*>[\s\S]*?</text>', caseSensitive: false),
      (_) => '',
    );

    result = result.replaceAllMapped(RegExp(r'<path([^>]*?)>'), (match) {
      final attrs = match.group(1) ?? '';
      if (attrs.contains('fill=')) return '<path$attrs>';
      return '<path$attrs fill="#ffffff">';
    });

    return result;
  }

  int? _resolveSurahNumber(String text, Map<String, int> surahNameToNumber) {
    final normalized = _normalizeArabic(text);
    var surahNumber = surahNameToNumber[normalized];
    if (surahNumber == null && normalized.isNotEmpty) {
      for (final entry in surahNameToNumber.entries) {
        if (entry.key.contains(normalized) || normalized.contains(entry.key)) {
          surahNumber = entry.value;
          break;
        }
      }
    }
    return surahNumber;
  }

  Path? _tryParsePath(String rawPath) {
    String upperCommands(String value) {
      return value.replaceAllMapped(RegExp(r'[a-zA-Z]'), (m) {
        return m.group(0)!.toUpperCase();
      });
    }

    final normalized = rawPath.replaceAll(RegExp(r'\s+'), ' ').trim();
    final candidates = <String>[
      rawPath,
      rawPath.replaceAll(',', ' '),
      normalized,
      upperCommands(normalized),
    ];

    for (final candidate in candidates) {
      try {
        return parseSvgPathData(candidate);
      } catch (_) {
        // Try next candidate.
      }
    }
    return null;
  }

  Map<String, String> _buildPathDataMap(String raw) {
    final map = <String, String>{};
    final pathTagPattern = RegExp(r'<path[^>]*>', caseSensitive: false);
    final attrPattern = RegExp(r'([a-zA-Z:-]+)="([^"]*)"');

    for (final match in pathTagPattern.allMatches(raw)) {
      final tag = match.group(0) ?? '';
      String? id;
      String? d;
      for (final attr in attrPattern.allMatches(tag)) {
        final key = attr.group(1);
        final value = attr.group(2);
        if (key == 'id') {
          id = value;
        } else if (key == 'd') {
          d = value;
        }
      }
      if (id != null && d != null) {
        map[id] = d;
      }
    }
    return map;
  }

  String _normalizeArabic(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll(RegExp(r'^سورة\s*'), '')
        .replaceAll(RegExp(r'^ال'), '')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[إأآا]'), 'ا')
        .replaceAll(RegExp(r'[ىي]'), 'ي')
        .replaceAll(RegExp(r'[ةه]'), 'ه')
        .replaceAll('\u0640', '')
        .replaceAll(RegExp(r'\s+'), '');
  }
}
