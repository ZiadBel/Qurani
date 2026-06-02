import "package:qurani/l10n/app_localizations.dart";
import "package:qurani/src/resources/translation/language_cubit.dart";
import "package:flutter/cupertino.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:intl/intl.dart";

String localizedNumber(BuildContext context, dynamic number) {
  final Locale currentLocale = context.read<LanguageCubit>().state.locale;
  if (number.runtimeType == double) {
    return NumberFormat.decimalPattern(
      currentLocale.languageCode,
    ).format(number as double);
  } else if (number.runtimeType == int) {
    return NumberFormat.decimalPattern(
      currentLocale.languageCode,
    ).format(number as int);
  } else {
    return number.toString();
  }
}

/// Convert Latin digits in [input] to Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩).
String toArabicDigits(String input) {
  const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final buf = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buf.write(arabicIndic[rune - 0x30]);
    } else {
      buf.writeCharCode(rune);
    }
  }
  return buf.toString();
}

/// Render an "X verses" label using proper Arabic grammar:
///   1   → آية واحدة
///   2   → آيتان
///   3-10 → ٣ آيات
///   11+ → ٢٨٦ آية
///
/// Falls back to the locale's `ayahsCount` (e.g. "7 Ayahs") in non-Arabic
/// locales so the original l10n strings continue to drive other languages.
String formatAyahCount(BuildContext context, int count) {
  final locale = context.read<LanguageCubit>().state.locale;
  if (locale.languageCode != 'ar') {
    return AppLocalizations.of(context).ayahsCount(
      localizedNumber(context, count),
    );
  }

  if (count == 1) return 'آية واحدة';
  if (count == 2) return 'آيتان';
  final digits = localizedNumber(context, count);
  if (count >= 3 && count <= 10) return '$digits آيات';
  return '$digits آية';
}
