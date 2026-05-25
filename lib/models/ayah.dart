// ============================================================================
// SACRED CONTENT NOTICE
// ----------------------------------------------------------------------------
// `Ayah.text` carries the verbatim Quranic Arabic loaded from the approved
// JSON asset. It MUST NOT be normalized, trimmed, translated, regenerated, or
// modified in any code path. Treat it as opaque, immutable byte content for
// display only.
// ============================================================================
import 'package:flutter/foundation.dart';

@immutable
class Ayah {
  final int number;
  final String text;

  const Ayah({required this.number, required this.text});

  factory Ayah.fromJson(Map<String, dynamic> json) {
    final n = json['number'];
    final t = json['text'];
    if (n is! int) {
      throw FormatException('Ayah.number must be int, got $n');
    }
    if (t is! String || t.isEmpty) {
      throw FormatException('Ayah.text must be non-empty string');
    }
    // Pass-through. NO trimming or normalization.
    return Ayah(number: n, text: t);
  }
}
