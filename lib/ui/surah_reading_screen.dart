// ============================================================================
// SACRED CONTENT NOTICE
// ----------------------------------------------------------------------------
// This screen DISPLAYS Quranic Arabic that is loaded by QuranRepository from
// the approved local asset. The widget tree must not transform, normalize, or
// otherwise modify any Arabic string. It only renders Text widgets containing
// the verbatim ayah text and the verbatim surah name. Pagination is purely
// presentational and never edits any verse.
// ============================================================================
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/bookmark_service.dart';
import '../data/quran_repository.dart';
import '../models/ayah.dart';
import '../models/surah.dart';
import 'mushaf_paginator.dart';
import 'reading_palette.dart';

class SurahReadingScreen extends StatefulWidget {
  final int surahNumber;
  final int initialAyah;

  const SurahReadingScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah = 1,
  });

  @override
  State<SurahReadingScreen> createState() => _SurahReadingScreenState();
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  late Future<List<Surah>> _future;

  @override
  void initState() {
    super.initState();
    _future = QuranRepository.instance.loadAllSurahs();
    BookmarkService.instance
        .save(surah: widget.surahNumber, ayah: widget.initialAyah);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ReadingPalette.of(theme);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: palette.muted),
        ),
        body: SafeArea(
          child: FutureBuilder<List<Surah>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Center(
                  child: CircularProgressIndicator(color: palette.accent),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'تعذّر تحميل القرآن.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.ink),
                    ),
                  ),
                );
              }
              return _LazyMushafReader(
                allSurahs: snap.data!,
                startSurah: widget.surahNumber,
                startAyah: widget.initialAyah,
                palette: palette,
              );
            },
          ),
        ),
      ),
    );
  }
}

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

/// Reader that paginates lazily: starts by paginating the requested surah
/// (and the next one for smooth continuous flow), then extends the page
/// list one surah at a time as the user nears the tail.
class _LazyMushafReader extends StatefulWidget {
  final List<Surah> allSurahs;
  final int startSurah;
  final int startAyah;
  final ReadingPalette palette;

  const _LazyMushafReader({
    required this.allSurahs,
    required this.startSurah,
    required this.startAyah,
    required this.palette,
  });

  @override
  State<_LazyMushafReader> createState() => _LazyMushafReaderState();
}

class _LazyMushafReaderState extends State<_LazyMushafReader> {
  late PageController _pageController;
  late Map<int, Surah> _surahByNumber;

  /// All pages currently realized. Grows monotonically as the user swipes
  /// past the tail (we never rebuild past pages).
  List<MushafPage> _pages = const [];

  /// Highest surah-index (0-based) we've paginated. We start by paginating
  /// from [startSurah - 1] up through this index inclusive.
  int _lastSurahIdxPaginated = -1;
  Size? _lastPanelSize;
  bool _initialJumpDone = false;

  // Pre-build a buffer (3 pages) ahead of where the user is currently.
  static const int _prefetchPagesAhead = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _surahByNumber = {for (final s in widget.allSurahs) s.number: s};
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resetForPanelSize(Size panelSize) {
    _pages = const [];
    _lastSurahIdxPaginated = -1;
    _lastPanelSize = panelSize;
    _initialJumpDone = false;
    // Paginate starting surah and (if it exists) the one after for natural
    // cross-surah flow on the first batch.
    final startIdx =
        (widget.startSurah - 1).clamp(0, widget.allSurahs.length - 1);
    _paginateSurahRange(startIdx, startIdx + 1, panelSize);
  }

  /// Paginate the slice [fromIdx..toIdx] inclusive (both clamped) and APPEND
  /// the resulting pages.
  void _paginateSurahRange(int fromIdx, int toIdx, Size panelSize) {
    final from = fromIdx.clamp(0, widget.allSurahs.length - 1);
    final to = toIdx.clamp(0, widget.allSurahs.length - 1);
    if (from > to) return;
    final slice = widget.allSurahs.sublist(from, to + 1);
    final paginator = QuranPaginator(
      surahs: slice,
      panelSize: panelSize,
      baseStyle: TextStyle(
        fontFamily: 'AmiriQuran',
        fontSize: 26,
        height: 2.15,
        color: widget.palette.ink,
      ),
      markerStyle: TextStyle(
        fontFamily: 'AmiriQuran',
        color: widget.palette.accent,
        fontSize: 22,
      ),
      arabicNumber: _arabicNumber,
    );
    final newPages = paginator.paginate();
    _pages = [..._pages, ...newPages];
    _lastSurahIdxPaginated = to;
  }

  /// Called after each page change. If we're nearing the tail and there are
  /// more surahs to load, paginate the next surah and rebuild itemCount.
  void _maybeExtend(int currentPage) {
    if (_lastPanelSize == null) return;
    if (_lastSurahIdxPaginated + 1 >= widget.allSurahs.length) return; // done
    if (currentPage < _pages.length - _prefetchPagesAhead) return;
    // Extend by one surah at a time so the jank stays small.
    final nextIdx = _lastSurahIdxPaginated + 1;
    setState(() {
      _paginateSurahRange(nextIdx, nextIdx, _lastPanelSize!);
    });
  }

  int _pageContaining(int surah, int ayah) {
    for (var i = 0; i < _pages.length; i++) {
      final p = _pages[i];
      final beforeOrEqualStart = surah > p.firstSurah ||
          (surah == p.firstSurah && ayah >= p.firstAyah);
      final beforeOrEqualEnd = surah < p.lastSurah ||
          (surah == p.lastSurah && ayah <= p.lastAyah);
      if (beforeOrEqualStart && beforeOrEqualEnd) return i;
    }
    return 0;
  }

  Future<void> _markAyah(Surah s, Ayah a) async {
    await BookmarkService.instance.save(surah: s.number, ayah: a.number);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('تم حفظ سورة ${s.name} - آية ${_arabicNumber(a.number)}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// The header label always reflects the FIRST surah on the page (i.e.
  /// what the reader sees at the top), even if a later surah on the same
  /// page has more text. For cross-surah pages, the in-page banner makes
  /// the transition obvious so the top label staying on the first surah
  /// matches reader expectations.
  Surah _headerSurahFor(MushafPage page) {
    return _surahByNumber[page.firstSurah]!;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 18.0;
        // Compact header (the styled banner takes ~46px) + a hair of safety.
        const headerHeight = 46.0;
        final panelWidth = constraints.maxWidth - horizontalPadding * 2;
        final panelHeight = constraints.maxHeight - headerHeight - 6;
        final panelSize = Size(
          panelWidth.clamp(50.0, double.infinity),
          panelHeight.clamp(50.0, double.infinity),
        );

        if (_lastPanelSize != panelSize) {
          _resetForPanelSize(panelSize);
        }

        if (_pages.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: palette.accent),
          );
        }

        if (!_initialJumpDone) {
          _initialJumpDone = true;
          final startPage =
              _pageContaining(widget.startSurah, widget.startAyah);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_pageController.hasClients) return;
            if (_pageController.page?.round() != startPage) {
              _pageController.jumpToPage(startPage);
            }
          });
        }

        return PageView.builder(
          key: const ValueKey('mushaf_pageview'),
          controller: _pageController,
          reverse: true,
          itemCount: _pages.length,
          onPageChanged: (i) => _maybeExtend(i),
          itemBuilder: (context, i) {
            final page = _pages[i];
            return _MushafPageWidget(
              page: page,
              palette: palette,
              horizontalPadding: horizontalPadding,
              dominantSurahName: _headerSurahFor(page).name,
              onMarkAyah: _markAyah,
            );
          },
        );
      },
    );
  }
}

class _MushafPageWidget extends StatelessWidget {
  final MushafPage page;
  final ReadingPalette palette;
  final double horizontalPadding;
  final String dominantSurahName;
  final void Function(Surah, Ayah) onMarkAyah;

  const _MushafPageWidget({
    required this.page,
    required this.palette,
    required this.horizontalPadding,
    required this.dominantSurahName,
    required this.onMarkAyah,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < page.segments.length; i++) {
      final seg = page.segments[i];
      if (seg is BannerSegment) {
        children.add(SurahBanner(name: seg.surah.name, palette: palette));
      } else if (seg is TextSegment) {
        children.add(_TextSegmentWidget(
          segment: seg,
          palette: palette,
          onMarkAyah: onMarkAyah,
          gestureKey: i == _firstTextSegmentIndex
              ? const ValueKey('mushaf_gesture')
              : null,
        ));
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Opening surah header — same visual language as the in-page banner.
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: SurahBanner(
              name: dominantSurahName,
              palette: palette,
              compact: true,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, innerC) {
                return SingleChildScrollView(
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: innerC.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int get _firstTextSegmentIndex {
    for (var i = 0; i < page.segments.length; i++) {
      if (page.segments[i] is TextSegment) return i;
    }
    return -1;
  }
}

class _TextSegmentWidget extends StatefulWidget {
  final TextSegment segment;
  final ReadingPalette palette;
  final void Function(Surah, Ayah) onMarkAyah;
  final Key? gestureKey;

  const _TextSegmentWidget({
    required this.segment,
    required this.palette,
    required this.onMarkAyah,
    this.gestureKey,
  });

  @override
  State<_TextSegmentWidget> createState() => _TextSegmentWidgetState();
}

class _TextSegmentWidgetState extends State<_TextSegmentWidget> {
  final GlobalKey _richKey = GlobalKey();

  void _handleLongPress(LongPressStartDetails details) {
    final ro = _richKey.currentContext?.findRenderObject();
    if (ro is! RenderParagraph) return;
    final local = ro.globalToLocal(details.globalPosition);
    final pos = ro.getPositionForOffset(local);
    final hit = pos.offset;
    PageAyahRange? target;
    for (final r in widget.segment.ranges) {
      if (hit >= r.start && hit <= r.end) {
        target = r;
        break;
      }
    }
    if (target == null && widget.segment.ranges.isNotEmpty) {
      final nearest = widget.segment.ranges.reduce(
          (a, b) => (hit - a.end).abs() < (hit - b.end).abs() ? a : b);
      target = nearest;
    }
    if (target != null) {
      widget.onMarkAyah(target.surah, target.ayah);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      key: widget.gestureKey,
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(),
          (instance) {
            instance.onLongPressStart = _handleLongPress;
          },
        ),
      },
      child: Text.rich(
        widget.segment.span,
        key: _richKey,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      ),
    );
  }
}

/// Shared ornamental Surah banner — used both for the opening header AND the
/// in-page divider between two surahs on the same page.
class SurahBanner extends StatelessWidget {
  final String name;
  final ReadingPalette palette;
  final bool compact;
  const SurahBanner({
    super.key,
    required this.name,
    required this.palette,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 0 : 14),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 16, vertical: compact ? 6 : 10),
        decoration: BoxDecoration(
          border: Border.all(color: palette.accent, width: 1.2),
          borderRadius: BorderRadius.circular(6),
          color: palette.accent.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.brightness_1, size: 4, color: palette.accent),
            const SizedBox(width: 10),
            Text(
              'سُورَةُ $name',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 10),
            Icon(Icons.brightness_1, size: 4, color: palette.accent),
          ],
        ),
      ),
    );
  }
}
