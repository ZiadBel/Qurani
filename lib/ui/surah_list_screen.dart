import 'package:flutter/material.dart';

import '../data/bookmark_service.dart';
import '../data/quran_repository.dart';
import '../data/search_service.dart';
import '../models/surah.dart';
import 'reading_palette.dart';
import 'surah_reading_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late Future<List<Surah>> _future;
  String _query = '';
  Bookmark? _bookmark;
  QuranSearch? _searcher;

  @override
  void initState() {
    super.initState();
    _future = QuranRepository.instance.loadAllSurahs();
    _future.then((surahs) {
      if (!mounted) return;
      _searcher = QuranSearch(surahs);
    });
    _refreshBookmark();
  }

  Future<void> _refreshBookmark() async {
    final b = await BookmarkService.instance.read();
    if (!mounted) return;
    setState(() => _bookmark = b);
  }

  Future<void> _openSurah(Surah s, {int initialAyah = 1}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReadingScreen(
          surahNumber: s.number,
          initialAyah: initialAyah,
        ),
      ),
    );
    _refreshBookmark();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ReadingPalette.of(theme);
    // Force RTL for the whole home screen so every directional API
    // (EdgeInsetsDirectional, AlignmentDirectional, ListTile leading/trailing,
    // Icons that auto-flip) resolves consistently.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'القرآن الكريم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: palette.accent,
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<List<Surah>>(
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
                    'تعذّر تحميل بيانات القرآن.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.ink),
                  ),
                ),
              );
            }
            final all = snap.data!;
            final searcher = _searcher ?? QuranSearch(all);

            final hasQuery = _query.trim().isNotEmpty;
            return Column(
              children: [
                if (_bookmark != null && !hasQuery)
                  _LastReadHero(
                    bookmark: _bookmark!,
                    surahs: all,
                    palette: palette,
                    onTap: (s, a) => _openSurah(s, initialAyah: a),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 8),
                  child: _SearchField(
                    palette: palette,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: hasQuery
                      ? _SearchResultsList(
                          results: searcher.search(_query),
                          palette: palette,
                          onTapSurah: _openSurah,
                          onTapAyah: (s, a) =>
                              _openSurah(s, initialAyah: a),
                        )
                      : _SurahList(
                          all: all,
                          palette: palette,
                          onTap: _openSurah,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  final List<Surah> all;
  final ReadingPalette palette;
  final void Function(Surah) onTap;
  const _SurahList({
    required this.all,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: all.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        color: palette.muted.withValues(alpha: 0.15),
        indent: 18,
        endIndent: 18,
      ),
      itemBuilder: (context, i) {
        final s = all[i];
        return _SurahTile(surah: s, palette: palette, onTap: () => onTap(s));
      },
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;
  final ReadingPalette palette;
  final VoidCallback onTap;
  const _SurahTile({
    required this.surah,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        child: Row(
          // In RTL, Row places the FIRST child on the right (the start side).
          // Order children in logical (start → end) order: number disk first
          // so it sits at the right (leading position), then the text block
          // flows to its left.
          children: [
            // Number disk — RTL "leading" position (visually on the right).
            Container(
              width: 36,
              height: 36,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accentSoft,
                border:
                    Border.all(color: palette.accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                surah.number.toString(),
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                // CrossAxisAlignment.start = right in RTL → Arabic text
                // aligns to its natural reading edge (right side of the
                // text block, which sits to the LEFT of the number disk).
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.numberOfAyahs} آية  ·  '
                    '${surah.revelationType == "Meccan" ? "مكية" : "مدنية"}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ReadingPalette palette;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.palette, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // TextField + InputDecoration automatically pick up the ambient
    // Directionality for both the input text and the hint, so prefix/suffix
    // icons flip correctly. We just need to NOT override textDirection here.
    return TextField(
      onChanged: onChanged,
      // No textDirection override — inherit the screen's RTL.
      style: TextStyle(color: palette.ink, fontFamily: 'Amiri', fontSize: 16),
      cursorColor: palette.accent,
      decoration: InputDecoration(
        hintText: 'ابحث باسم السورة أو نصّ الآية',
        hintStyle: TextStyle(color: palette.muted, fontFamily: 'Amiri'),
        prefixIcon: Icon(Icons.search, color: palette.muted),
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: palette.muted.withValues(alpha: 0.25),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: palette.muted.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: palette.accent.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

class _LastReadHero extends StatelessWidget {
  final Bookmark bookmark;
  final List<Surah> surahs;
  final ReadingPalette palette;
  final void Function(Surah, int) onTap;
  const _LastReadHero({
    required this.bookmark,
    required this.surahs,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = surahs.firstWhere(
      (s) => s.number == bookmark.surah,
      orElse: () => surahs.first,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap(s, bookmark.ayah),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              // RTL row: book icon at the start (right), chevron at the end
              // (left). The chevron uses `arrow_forward_ios` which the
              // Material icon library AUTO-FLIPS for RTL — so the visible
              // glyph points leftward (the "forward" direction in RTL).
              children: [
                Icon(Icons.menu_book, color: palette.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متابعة القراءة',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          color: palette.muted,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'سورة ${s.name} · آية ${bookmark.ayah}',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios,
                    color: palette.accent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final ReadingPalette palette;
  final void Function(Surah) onTapSurah;
  final void Function(Surah, int) onTapAyah;

  const _SearchResultsList({
    required this.results,
    required this.palette,
    required this.onTapSurah,
    required this.onTapAyah,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: palette.muted,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        color: palette.muted.withValues(alpha: 0.15),
        indent: 18,
        endIndent: 18,
      ),
      itemBuilder: (context, i) {
        final r = results[i];
        if (r is SurahNameResult) {
          return _SurahTile(
            surah: r.surah,
            palette: palette,
            onTap: () => onTapSurah(r.surah),
          );
        }
        if (r is AyahTextResult) {
          return _AyahResultTile(
            result: r,
            palette: palette,
            onTap: () => onTapAyah(r.surah, r.ayah.number),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _AyahResultTile extends StatelessWidget {
  final AyahTextResult result;
  final ReadingPalette palette;
  final VoidCallback onTap;
  const _AyahResultTile({
    required this.result,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
        child: Column(
          // start = right in RTL — the surah label and verse text both
          // start from the reader's natural reading edge (the right side).
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // start-aligned: label sits on the right (where the eye lands
              // first when reading RTL); the "تقريبي" badge sits to its left.
              children: [
                Text(
                  'سورة ${result.surah.name} · آية ${result.ayah.number}',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: palette.muted,
                  ),
                ),
                if (!result.exact) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'تقريبي',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 11,
                        color: palette.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              result.ayah.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 20,
                height: 1.9,
                color: palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
