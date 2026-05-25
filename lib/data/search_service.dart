// ============================================================================
// SACRED CONTENT NOTICE
// ----------------------------------------------------------------------------
// SearchService reads verses to find matches. It NEVER modifies the asset
// or the in-memory Ayah/Surah models. The diacritic-stripped "normalized"
// text is computed once per search at runtime and discarded; the original
// asset bytes are not touched.
// ============================================================================
import '../models/ayah.dart';
import '../models/surah.dart';

/// One match found in the corpus.
sealed class SearchResult {
  const SearchResult();
}

class SurahNameResult extends SearchResult {
  final Surah surah;
  const SurahNameResult(this.surah);
}

class AyahTextResult extends SearchResult {
  final Surah surah;
  final Ayah ayah;
  /// Whether the match was an exact substring (true) or required
  /// diacritic-stripping to find (false).
  final bool exact;
  const AyahTextResult({
    required this.surah,
    required this.ayah,
    required this.exact,
  });
}

class QuranSearch {
  final List<Surah> corpus;
  QuranSearch(this.corpus);

  /// Returns up to [limit] results. Surah-name matches come first, then ayah
  /// matches. Empty queries return an empty list.
  ///
  /// Match algorithm:
  ///   1. Trim the query. If empty, return [].
  ///   2. Check surah name containment (Arabic or Western digits).
  ///   3. Check ayah text containment (exact substring against the verbatim
  ///      Tanzil text).
  ///   4. If no ayah results yet, fall back to a diacritic-stripped match:
  ///      strip Arabic diacritics + tatweel from both query and verse text
  ///      and try again. Verses whose stripped form contains the stripped
  ///      query are returned with [AyahTextResult.exact] == false.
  List<SearchResult> search(String rawQuery, {int limit = 50}) {
    final q = rawQuery.trim();
    if (q.isEmpty) return const [];

    final results = <SearchResult>[];

    // 1. Surah names + numbers.
    final qLower = q.toLowerCase();
    for (final s in corpus) {
      if (results.length >= limit) break;
      if (s.name.contains(q) || s.number.toString() == qLower) {
        results.add(SurahNameResult(s));
      }
    }

    // 2. Exact ayah substring.
    final exactAyahs = <AyahTextResult>[];
    for (final s in corpus) {
      for (final a in s.ayahs) {
        if (a.text.contains(q)) {
          exactAyahs.add(AyahTextResult(surah: s, ayah: a, exact: true));
          if (results.length + exactAyahs.length >= limit) break;
        }
      }
      if (results.length + exactAyahs.length >= limit) break;
    }
    results.addAll(exactAyahs);

    // 3. Diacritic-stripped fallback only if no exact ayah hits.
    if (exactAyahs.isEmpty && results.length < limit) {
      final qStripped = _stripDiacritics(q);
      if (qStripped.isNotEmpty) {
        for (final s in corpus) {
          if (results.length >= limit) break;
          for (final a in s.ayahs) {
            if (_stripDiacritics(a.text).contains(qStripped)) {
              results.add(AyahTextResult(surah: s, ayah: a, exact: false));
              if (results.length >= limit) break;
            }
          }
        }
      }
    }

    return results;
  }
}

/// Removes Arabic combining marks (harakat) and tatweel so that user input
/// without diacritics still matches the Uthmani-typeset corpus.
///
/// This is applied only to a transient COPY of the verse text during search;
/// the source asset and the in-memory Ayah objects are never modified.
String _stripDiacritics(String s) {
  final buf = StringBuffer();
  for (final cu in s.runes) {
    // Arabic diacritics: U+064B..U+065F (harakat), U+06D6..U+06ED (Quranic
    // marks), U+0640 (tatweel) are stripped entirely.
    if ((cu >= 0x064B && cu <= 0x065F) ||
        (cu >= 0x06D6 && cu <= 0x06ED) ||
        cu == 0x0640) {
      continue;
    }
    var c = cu;
    // U+0670 (superscript alif) is phonetically an alif that the Mushaf
    // omits from the rasm but a plain-typing user would write. Promote it
    // to a real alif so plain-Arabic input matches the Mushaf rasm.
    if (c == 0x0670) {
      c = 0x0627;
    }
    // Normalize a few common alif forms so 'ا' matches 'ٱ'/'إ'/'أ'/'آ'.
    if (c == 0x0671 || c == 0x0622 || c == 0x0623 || c == 0x0625) {
      c = 0x0627;
    }
    buf.writeCharCode(c);
  }
  return buf.toString();
}
