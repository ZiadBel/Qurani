// ============================================================================
// SACRED CONTENT NOTICE
// ----------------------------------------------------------------------------
// QuranRepository is the ONLY component that reads Quranic Arabic text. It
// reads exclusively from the bundled local asset `assets/quran/quran_uthmani.json`
// and exposes immutable model objects. It NEVER:
//   - fetches from the network;
//   - generates, normalizes, or modifies any Arabic text;
//   - accepts user-provided Quran content.
//
// Per project policy, the bundled asset's SHA-256 is verified at build time by
// scripts/validate_quran.py against scripts/quran_hash.txt. Any update to the
// Quran text must be done by replacing the source XML and refreshing both the
// JSON asset and the approved hash, after manual verification.
// ============================================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/ayah.dart';
import '../models/surah.dart';

class QuranRepository {
  static const String assetPath = 'assets/quran/quran_uthmani.json';

  static const int expectedSurahCount = 114;
  static const int expectedAyahTotal = 6236;

  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  Future<List<Surah>>? _loading;
  List<Surah>? _cache;

  Future<List<Surah>> loadAllSurahs() {
    if (_cache != null) return Future.value(_cache);
    return _loading ??= _loadFromAsset();
  }

  Future<Surah> getSurah(int number) async {
    final all = await loadAllSurahs();
    if (number < 1 || number > all.length) {
      throw RangeError('Surah number out of range: $number');
    }
    return all[number - 1];
  }

  Future<Ayah> getAyah(int surah, int ayah) async {
    final s = await getSurah(surah);
    if (ayah < 1 || ayah > s.ayahs.length) {
      throw RangeError('Ayah number out of range: $ayah in surah $surah');
    }
    return s.ayahs[ayah - 1];
  }

  Future<List<Surah>> _loadFromAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    final doc = json.decode(raw);
    if (doc is! Map<String, dynamic>) {
      throw const FormatException('Quran JSON root is not an object');
    }
    final list = doc['surahs'];
    if (list is! List) {
      throw const FormatException('Quran JSON missing "surahs" array');
    }
    final surahs = list
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    if (surahs.length != expectedSurahCount) {
      throw StateError(
        'Quran data integrity error: expected $expectedSurahCount surahs, '
        'got ${surahs.length}',
      );
    }
    var total = 0;
    for (final s in surahs) {
      total += s.ayahs.length;
    }
    if (total != expectedAyahTotal) {
      throw StateError(
        'Quran data integrity error: expected $expectedAyahTotal ayahs, '
        'got $total',
      );
    }
    _cache = surahs;
    return surahs;
  }
}
