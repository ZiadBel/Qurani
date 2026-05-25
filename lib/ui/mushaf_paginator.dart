// ============================================================================
// SACRED CONTENT NOTICE
// ----------------------------------------------------------------------------
// This file performs LAYOUT measurement of Quranic Arabic text. It NEVER
// modifies, normalizes, reorders, or transforms verse strings. It only reads
// them, builds inline spans for measurement, and decides where page
// boundaries fall — all transformations applied are presentational
// (font, color, marker glyph). The Quran text itself is passed through
// verbatim from the approved JSON asset via the Ayah model. The paginator
// never mutates its inputs.
// ============================================================================
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/ayah.dart';
import '../models/surah.dart';

/// One range of characters in a TextSegment belonging to a single
/// (surah, ayah) pair. Used at runtime to map a long-press hit offset back
/// to its surah and ayah so the correct bookmark can be saved.
typedef PageAyahRange = ({int start, int end, Surah surah, Ayah ayah});

/// A page is composed of one or more vertical segments stacked top-down.
sealed class PageSegment {
  const PageSegment();
}

/// A continuous block of text containing one or more ayahs from a single
/// surah. The [span] is what gets rendered with Text.rich; [ranges] map
/// long-press offsets back to their (surah, ayah).
class TextSegment extends PageSegment {
  final InlineSpan span;
  final List<PageAyahRange> ranges;
  const TextSegment({required this.span, required this.ranges});
}

/// A surah-name banner shown above the first ayah of every surah that
/// begins inside a page (NOT including the first surah being opened by
/// the reader — the screen's own top header handles that one).
class BannerSegment extends PageSegment {
  final Surah surah;
  const BannerSegment(this.surah);
}

/// A single Mushaf-style page assembled by [QuranPaginator].
class MushafPage {
  final List<PageSegment> segments;
  final int firstSurah;
  final int firstAyah;
  final int lastSurah;
  final int lastAyah;

  const MushafPage({
    required this.segments,
    required this.firstSurah,
    required this.firstAyah,
    required this.lastSurah,
    required this.lastAyah,
  });

  /// True when the page contains content from more than one surah.
  bool get isCrossSurah => firstSurah != lastSurah;
}

/// Greedy paginator that lays out a list of surahs into a continuous
/// sequence of Mushaf-style pages.
///
/// Pagination is always at AYAH boundaries within a surah. Pages may span
/// surah boundaries: when the final ayahs of one surah leave room on a
/// page, the next surah's banner is appended and as many of its ayahs as
/// fit are included on the same page.
class QuranPaginator {
  final List<Surah> surahs;
  final Size panelSize;
  final TextStyle baseStyle;
  final TextStyle markerStyle;

  /// Estimated banner height including its own top/bottom padding, used by
  /// the layout pass to reserve space when computing how many ayahs fit
  /// after a banner. The reading screen must render the banner at this
  /// same height (or smaller) to keep visual consistency.
  final double bannerHeight;

  final String Function(int) arabicNumber;

  QuranPaginator({
    required this.surahs,
    required this.panelSize,
    required this.baseStyle,
    required this.markerStyle,
    required this.arabicNumber,
    this.bannerHeight = 56.0,
  });

  /// Pages where a single ayah genuinely could not fit at the configured
  /// font/panel size. Reported for diagnostics.
  final List<int> overflowingPages = [];

  List<MushafPage> paginate() {
    overflowingPages.clear();
    if (surahs.isEmpty || panelSize.width <= 0 || panelSize.height <= 0) {
      return const [];
    }

    final pages = <MushafPage>[];

    // Track our position as (surahIndex, ayahIndex) within `surahs`.
    var sIdx = 0;
    var aIdx = 0;

    while (sIdx < surahs.length) {
      // Build one page by adding segments until we run out of room.
      final segments = <PageSegment>[];
      var remainingHeight = panelSize.height;
      int firstSurahNo = -1;
      int firstAyahNo = -1;
      int lastSurahNo = -1;
      int lastAyahNo = -1;

      // If we're at the first ayah of a surah AND it's not the very first
      // surah of the reading session AND nothing has been placed on this
      // page yet, insert a banner.
      bool isFreshPage = true;

      while (sIdx < surahs.length) {
        final surah = surahs[sIdx];

        // Insert a banner before the first ayah of a non-first surah.
        if (aIdx == 0 && sIdx != 0) {
          if (remainingHeight < bannerHeight + _approxLineHeight() * 2) {
            // Not enough room for a banner + at least 2 lines of text.
            // Finish the page here and start the banner on the next.
            if (!isFreshPage) break;
            // Page is fresh but still doesn't fit — emit the banner anyway
            // (rare, only on very short panels).
          }
          segments.add(BannerSegment(surah));
          remainingHeight -= bannerHeight;
          isFreshPage = false;
        }

        // Fit as many ayahs from this surah as possible into the remaining
        // height as a single TextSegment.
        final result = _fitAyahsFromSurah(
          surah: surah,
          startAyahIndex: aIdx,
          maxHeight: remainingHeight,
        );
        if (result.endAyahIndex < aIdx) {
          // Nothing fit (not even one ayah). If the page is empty, force
          // include the first ayah anyway and mark the page as overflowed.
          if (isFreshPage && segments.isEmpty) {
            final forced = _buildTextSegment(surah, aIdx, aIdx);
            segments.add(forced.segment);
            overflowingPages.add(pages.length);
            firstSurahNo = surah.number;
            firstAyahNo = surah.ayahs[aIdx].number;
            lastSurahNo = surah.number;
            lastAyahNo = surah.ayahs[aIdx].number;
            aIdx += 1;
            if (aIdx >= surah.ayahs.length) {
              sIdx += 1;
              aIdx = 0;
            }
          }
          break;
        }
        segments.add(result.segment);
        remainingHeight -= result.height;
        firstSurahNo = firstSurahNo == -1 ? surah.number : firstSurahNo;
        firstAyahNo =
            firstAyahNo == -1 ? surah.ayahs[aIdx].number : firstAyahNo;
        lastSurahNo = surah.number;
        lastAyahNo = surah.ayahs[result.endAyahIndex].number;
        isFreshPage = false;
        aIdx = result.endAyahIndex + 1;

        if (aIdx >= surah.ayahs.length) {
          // Move to next surah.
          sIdx += 1;
          aIdx = 0;
          // Add a small inter-segment buffer so the next surah's banner
          // doesn't crowd the previous surah's text.
          remainingHeight -= 8;
          if (remainingHeight < bannerHeight + _approxLineHeight() * 2) {
            break;
          }
          // Continue the loop to (possibly) place the next surah's banner
          // and ayahs on the same page.
        } else {
          // Still in the same surah but no more room.
          break;
        }
      }

      if (segments.isEmpty) {
        // Shouldn't happen, but guard.
        break;
      }
      pages.add(MushafPage(
        segments: segments,
        firstSurah: firstSurahNo,
        firstAyah: firstAyahNo,
        lastSurah: lastSurahNo,
        lastAyah: lastAyahNo,
      ));
    }
    return pages;
  }

  /// Approximation of a single text line's height at the configured style.
  /// Used to decide whether a banner + at least 2 lines can fit on a page.
  double _approxLineHeight() {
    final fontSize = baseStyle.fontSize ?? 22;
    final lineHeight = baseStyle.height ?? 1.4;
    return fontSize * lineHeight;
  }

  /// Find the largest [endAyahIndex] >= [startAyahIndex] such that ayahs
  /// `surah.ayahs[startAyahIndex..endAyahIndex]` rendered as a single
  /// justified RTL paragraph fit within [maxHeight] at [panelSize.width].
  /// Returns a built TextSegment for that range (and the actual height).
  ({TextSegment segment, int endAyahIndex, double height}) _fitAyahsFromSurah({
    required Surah surah,
    required int startAyahIndex,
    required double maxHeight,
  }) {
    if (maxHeight <= 0 || startAyahIndex >= surah.ayahs.length) {
      return (
        segment: const TextSegment(span: TextSpan(), ranges: []),
        endAyahIndex: startAyahIndex - 1,
        height: 0,
      );
    }
    var bestEnd = startAyahIndex - 1;
    var bestHeight = 0.0;
    InlineSpan bestSpan = const TextSpan();
    List<PageAyahRange> bestRanges = const [];

    for (var end = startAyahIndex; end < surah.ayahs.length; end++) {
      final built = _buildTextSegmentRaw(surah, startAyahIndex, end);
      if (built.height > maxHeight) {
        break;
      }
      bestEnd = end;
      bestHeight = built.height;
      bestSpan = built.span;
      bestRanges = built.ranges;
    }

    return (
      segment: TextSegment(span: bestSpan, ranges: bestRanges),
      endAyahIndex: bestEnd,
      height: bestHeight,
    );
  }

  /// Build a [TextSegment] for a known ayah range (used in the overflow
  /// edge case where a single ayah doesn't fit and we want to render it
  /// anyway).
  ({TextSegment segment, double height}) _buildTextSegment(
    Surah surah,
    int fromAyahIdx,
    int toAyahIdx,
  ) {
    final r = _buildTextSegmentRaw(surah, fromAyahIdx, toAyahIdx);
    return (
      segment: TextSegment(span: r.span, ranges: r.ranges),
      height: r.height,
    );
  }

  ({InlineSpan span, List<PageAyahRange> ranges, double height})
      _buildTextSegmentRaw(Surah surah, int fromAyahIdx, int toAyahIdx) {
    final children = <InlineSpan>[];
    final ranges = <PageAyahRange>[];
    var cursor = 0;

    for (var i = fromAyahIdx; i <= toAyahIdx; i++) {
      final a = surah.ayahs[i];
      final ayahStart = cursor;

      children.add(TextSpan(text: a.text));
      cursor += a.text.length;

      children.add(const TextSpan(text: ' '));
      cursor += 1;

      final marker = '۝${arabicNumber(a.number)}';
      children.add(TextSpan(text: marker, style: markerStyle));
      cursor += marker.length;

      ranges.add((
        start: ayahStart,
        end: cursor,
        surah: surah,
        ayah: a,
      ));

      if (i != toAyahIdx) {
        children.add(const TextSpan(text: ' '));
        cursor += 1;
      }
    }

    final span = TextSpan(style: baseStyle, children: children);
    final tp = TextPainter(
      text: span,
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: panelSize.width);
    return (span: span, ranges: ranges, height: tp.size.height);
  }
}
