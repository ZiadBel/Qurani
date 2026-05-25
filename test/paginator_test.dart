// ============================================================================
// Unit tests for QuranPaginator.
//
// Validates that:
//   - pagination is at AYAH boundaries within a surah;
//   - pages can span surah boundaries (continuous flow);
//   - every ayah in the input corpus appears in exactly one page;
//   - the verbatim ayah text passes through unchanged.
// ============================================================================
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurani/data/quran_repository.dart';
import 'package:qurani/ui/mushaf_paginator.dart';

const _baseStyle = TextStyle(
  fontFamily: 'AmiriQuran',
  fontSize: 26,
  height: 2.15,
);
const _markerStyle = TextStyle(
  fontFamily: 'AmiriQuran',
  fontSize: 22,
);

String _arabicNumber(int n) {
  const western = '0123456789';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in n.toString().split('')) {
    final i = western.indexOf(ch);
    buf.write(i >= 0 ? arabic[i] : ch);
  }
  return buf.toString();
}

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

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

QuranPaginator _newPaginator(List surahs) => QuranPaginator(
      surahs: surahs.cast(),
      panelSize: const Size(360, 600),
      baseStyle: _baseStyle,
      markerStyle: _markerStyle,
      arabicNumber: _arabicNumber,
    );

Iterable<PageAyahRange> _allRanges(MushafPage page) {
  return page.segments.whereType<TextSegment>().expand((s) => s.ranges);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _bindAssets();
    await _loadFont('AmiriQuran', 'assets/fonts/AmiriQuran.ttf');
    await _loadFont('Amiri', 'assets/fonts/Amiri-Regular.ttf');
  });

  test('paginates a single surah (Al-Fatihah) with ayah-boundary discipline',
      () async {
    final fatihah = await QuranRepository.instance.getSurah(1);
    final pages = _newPaginator([fatihah]).paginate();
    expect(pages, isNotEmpty);

    // Every ayah appears exactly once and consecutive pages are contiguous.
    final seen = <int>{};
    for (final p in pages) {
      for (var n = p.firstAyah; n <= p.lastAyah; n++) {
        expect(seen.contains(n), isFalse, reason: 'ayah $n on multiple pages');
        seen.add(n);
      }
    }
    expect(seen.length, fatihah.numberOfAyahs);
    for (var i = 1; i < pages.length; i++) {
      expect(pages[i].firstAyah, pages[i - 1].lastAyah + 1);
    }
  });

  test('paginates two consecutive surahs continuously — Al-Fatihah + Al-Baqarah',
      () async {
    final s1 = await QuranRepository.instance.getSurah(1);
    final s2 = await QuranRepository.instance.getSurah(2);
    final pages = _newPaginator([s1, s2]).paginate();

    expect(pages.first.firstSurah, 1);
    expect(pages.last.lastSurah, 2);

    // At least one page should be cross-surah, OR a page should start with
    // a BannerSegment for surah 2 (i.e. continuous flow into Al-Baqarah).
    var sawCrossOrBanner = false;
    for (final p in pages) {
      if (p.isCrossSurah) {
        sawCrossOrBanner = true;
        break;
      }
      for (final seg in p.segments) {
        if (seg is BannerSegment && seg.surah.number == 2) {
          sawCrossOrBanner = true;
          break;
        }
      }
      if (sawCrossOrBanner) break;
    }
    expect(sawCrossOrBanner, isTrue,
        reason: 'Pagination across Fatihah→Baqarah should produce either a '
            'cross-surah page or a page with the Baqarah banner.');

    // Every Fatihah ayah appears exactly once, in order.
    final fatihahAyahs = <int>[];
    for (final p in pages) {
      for (final r in _allRanges(p)) {
        if (r.surah.number == 1) fatihahAyahs.add(r.ayah.number);
      }
    }
    expect(fatihahAyahs, [1, 2, 3, 4, 5, 6, 7]);
  });

  test('verbatim ayah text is preserved', () async {
    final fatihah = await QuranRepository.instance.getSurah(1);
    final pages = _newPaginator([fatihah]).paginate();
    final allRanges = pages.expand(_allRanges).toList();
    expect(allRanges.length, fatihah.numberOfAyahs);
    for (var i = 0; i < fatihah.numberOfAyahs; i++) {
      expect(allRanges[i].ayah.text, fatihah.ayahs[i].text);
      expect(allRanges[i].ayah.text.codeUnits,
          fatihah.ayahs[i].text.codeUnits);
    }
  });

  test('paginates Al-Baqarah into many pages, mostly within panel height',
      () async {
    final baqarah = await QuranRepository.instance.getSurah(2);
    final paginator = _newPaginator([baqarah]);
    final pages = paginator.paginate();
    expect(pages.length, greaterThan(20));

    var coveredCount = 0;
    for (final p in pages) {
      coveredCount += (p.lastAyah - p.firstAyah + 1);
    }
    expect(coveredCount, 286);
    expect(paginator.overflowingPages.length, lessThan(5));
  });
}
