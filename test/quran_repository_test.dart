import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurani/data/quran_repository.dart';

/// Returns the asset bytes by reading the file directly. We do this rather
/// than going through rootBundle so the test does not depend on Flutter
/// asset bundling (which requires a full build).
Future<ByteData> _loadAssetFromDisk() async {
  final file = File('assets/quran/quran_uthmani.json');
  expect(file.existsSync(), isTrue,
      reason: 'Quran asset missing at ${file.path}');
  final bytes = await file.readAsBytes();
  return ByteData.view(bytes.buffer);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == QuranRepository.assetPath) {
        return _loadAssetFromDisk();
      }
      return null;
    });
  });

  test('loads exactly 114 surahs and 6236 ayahs from the approved asset',
      () async {
    final repo = QuranRepository.instance;
    final surahs = await repo.loadAllSurahs();
    expect(surahs.length, 114);
    var total = 0;
    for (var i = 0; i < surahs.length; i++) {
      expect(surahs[i].number, i + 1, reason: 'Surah at index $i has wrong number');
      expect(surahs[i].name, isNotEmpty);
      expect(surahs[i].ayahs.length, surahs[i].numberOfAyahs);
      total += surahs[i].ayahs.length;
    }
    expect(total, 6236);
  });

  test('per-surah ayah counts match the canonical mushaf', () async {
    const canonical = <int>[
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
      123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
      112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
      34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
      54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
      60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
      14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
      28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
      29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
      15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
      11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
      5, 4, 5, 6,
    ];
    final surahs = await QuranRepository.instance.loadAllSurahs();
    for (var i = 0; i < 114; i++) {
      expect(surahs[i].ayahs.length, canonical[i],
          reason: 'Surah ${i + 1} ayah count mismatch');
    }
  });

  test('getAyah returns the verbatim asset text without modification',
      () async {
    final repo = QuranRepository.instance;
    // Load the file independently and compare bytes.
    final raw = await File('assets/quran/quran_uthmani.json').readAsString();
    final doc = json.decode(raw) as Map<String, dynamic>;
    final surahs = doc['surahs'] as List;
    final firstSurah = surahs.first as Map<String, dynamic>;
    final firstAyah = (firstSurah['ayahs'] as List).first as Map<String, dynamic>;
    final expectedText = firstAyah['text'] as String;

    final loaded = await repo.getAyah(1, 1);
    expect(loaded.text, expectedText);
    // Verify no transformation at the codepoint level.
    expect(loaded.text.codeUnits, expectedText.codeUnits);
  });
}
