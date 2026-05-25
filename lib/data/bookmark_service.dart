import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class Bookmark {
  final int surah;
  final int ayah;
  const Bookmark({required this.surah, required this.ayah});
}

class BookmarkService {
  static const _kSurah = 'last_read_surah';
  static const _kAyah = 'last_read_ayah';

  BookmarkService._();
  static final BookmarkService instance = BookmarkService._();

  Future<Bookmark?> read() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getInt(_kSurah);
    final a = p.getInt(_kAyah);
    if (s == null || a == null) return null;
    return Bookmark(surah: s, ayah: a);
  }

  Future<void> save({required int surah, required int ayah}) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSurah, surah);
    await p.setInt(_kAyah, ayah);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSurah);
    await p.remove(_kAyah);
  }
}
