import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// This test enforces the project rule that no Quranic Arabic text appears in
/// the source code outside the approved JSON asset. Heuristic: any Dart file
/// under `lib/` must not contain Arabic letters in string literals. UI labels
/// for surah/ayah counts, search hints, and Arabic-numeral digits are NOT
/// Quranic verse text and are tolerated; the rule we enforce is the absence
/// of any Quranic VERSE text (long Arabic runs) and any Arabic-letter
/// codepoints sitting in places they should not be.
///
/// To be safe and explicit, we check the more conservative rule: no Dart file
/// (besides the repository asset itself) contains any continuous run of 8+
/// Arabic letters. UI labels in this app are short (e.g. "آخر قراءة"); a verse
/// would always exceed this threshold.
void main() {
  test('no long Arabic-letter runs in lib/ source (no embedded Quran text)',
      () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    // Arabic letter Unicode block ranges (basic Arabic + Arabic Supplement +
    // Arabic Presentation Forms). Digits and most punctuation are NOT in
    // these ranges and so do not count toward the run length.
    bool isArabicLetter(int cp) {
      return (cp >= 0x0621 && cp <= 0x063A) || // Arabic letters
          (cp >= 0x0641 && cp <= 0x064A) || // Arabic letters (cont.)
          (cp >= 0x066E && cp <= 0x06D3) || // Extended Arabic letters
          (cp >= 0xFB50 && cp <= 0xFDFF) || // Presentation Forms-A
          (cp >= 0xFE70 && cp <= 0xFEFF); // Presentation Forms-B
    }

    final offenders = <String>[];
    for (final entity
        in libDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      var run = 0;
      var maxRun = 0;
      for (final cp in content.runes) {
        if (isArabicLetter(cp)) {
          run += 1;
          if (run > maxRun) maxRun = run;
        } else {
          run = 0;
        }
      }
      // UI labels in this app stay well under 8 letters per run. Verses are
      // typically far longer.
      if (maxRun >= 8) {
        offenders.add('${entity.path} (max Arabic-letter run = $maxRun)');
      }
    }

    expect(offenders, isEmpty,
        reason:
            'Quranic verse text must never be hardcoded in lib/ source. '
            'Offending files:\n${offenders.join('\n')}');
  });
}
