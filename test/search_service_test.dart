// ============================================================================
// Unit tests for QuranSearch.
// ============================================================================
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurani/data/quran_repository.dart';
import 'package:qurani/data/search_service.dart';

Future<void> _bindAssets() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    final f = File(key);
    if (f.existsSync()) {
      return ByteData.view(f.readAsBytesSync().buffer);
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_bindAssets);

  test('finds Al-Fatihah by exact Arabic surah name', () async {
    final corpus = await QuranRepository.instance.loadAllSurahs();
    final results = QuranSearch(corpus).search('الفاتحة');
    expect(results, isNotEmpty);
    expect(results.first, isA<SurahNameResult>());
    expect((results.first as SurahNameResult).surah.number, 1);
  });

  test('finds surah by number string', () async {
    final corpus = await QuranRepository.instance.loadAllSurahs();
    final results = QuranSearch(corpus).search('18');
    expect(results.whereType<SurahNameResult>().any((r) => r.surah.number == 18),
        isTrue);
  });

  test('exact ayah text substring matches', () async {
    final corpus = await QuranRepository.instance.loadAllSurahs();
    // Take a real ayah string from the corpus and use a slice of it as the
    // query. We use the first ayah of Al-Fatihah for stability.
    final firstAyahText = corpus[0].ayahs[0].text;
    final slice = firstAyahText.substring(0, firstAyahText.length ~/ 2);
    final results = QuranSearch(corpus).search(slice);
    final ayahResults = results.whereType<AyahTextResult>().toList();
    expect(ayahResults, isNotEmpty);
    // At least one result should be marked exact and refer to a valid ayah.
    expect(ayahResults.any((r) => r.exact), isTrue);
  });

  test('diacritic-stripped fallback finds verses when plain Arabic is typed',
      () async {
    final corpus = await QuranRepository.instance.loadAllSurahs();
    // Typed without diacritics; the corpus has full tashkeel.
    final results = QuranSearch(corpus).search('الحمد لله رب العالمين');
    final ayahHits = results.whereType<AyahTextResult>().toList();
    expect(ayahHits, isNotEmpty,
        reason: 'Plain-Arabic query should find tashkeel-rich verse via '
            'diacritic-stripped fallback');
    // It should match Al-Fatihah ayah 2 among the results.
    expect(
      ayahHits.any((r) => r.surah.number == 1 && r.ayah.number == 2),
      isTrue,
    );
  });

  test('empty query returns no results', () async {
    final corpus = await QuranRepository.instance.loadAllSurahs();
    expect(QuranSearch(corpus).search('   '), isEmpty);
  });

  test('search caps at the configured limit', () async {
    final corpus = await QuranRepository.instance.loadAllSurahs();
    // 'الله' appears in many verses; ensure we cap.
    final results = QuranSearch(corpus).search('الله', limit: 25);
    expect(results.length, lessThanOrEqualTo(25));
  });
}
