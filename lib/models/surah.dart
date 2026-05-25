// ============================================================================
// SACRED CONTENT NOTICE
// ----------------------------------------------------------------------------
// `Surah.name` (Arabic name) and the contents of `Surah.ayahs` come directly
// from the approved Quran JSON asset. No code path may alter Arabic content.
// ============================================================================
import 'package:flutter/foundation.dart';

import 'ayah.dart';

@immutable
class Surah {
  final int number;
  final String name;
  final String revelationType;
  final int numberOfAyahs;
  final List<Ayah> ayahs;

  const Surah({
    required this.number,
    required this.name,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    final ayahsJson = json['ayahs'];
    if (ayahsJson is! List) {
      throw const FormatException('Surah.ayahs must be a list');
    }
    final ayahs = ayahsJson
        .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      revelationType: json['revelationType'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      ayahs: ayahs,
    );
  }
}
