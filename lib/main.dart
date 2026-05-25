// ============================================================================
// SACRED CONTENT NOTICE
// ----------------------------------------------------------------------------
// All Quranic Arabic content shown in this app comes EXCLUSIVELY from the
// approved local asset `assets/quran/quran_uthmani.json`, sourced from the
// Tanzil Project (Uthmani, Hafs). The asset is verified by SHA-256 before
// build via scripts/validate_quran.py.
//
// Do not hardcode, generate, fetch, or otherwise introduce Quranic text from
// any other source anywhere in this codebase.
// ============================================================================
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/surah_list_screen.dart';

void main() {
  // Device Preview is for development/debug only. In release mode the wrapper
  // is bypassed so it has zero runtime/footprint impact in production builds.
  final enableDevicePreview = !kReleaseMode;
  runApp(
    DevicePreview(
      enabled: enableDevicePreview,
      builder: (_) => const QuraniApp(),
    ),
  );
}

class QuraniApp extends StatelessWidget {
  const QuraniApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData buildTheme(Brightness b) {
      final t = ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
        brightness: b,
      );
      return t.copyWith(textTheme: t.textTheme.apply(fontFamily: 'Amiri'));
    }

    return MaterialApp(
      title: 'القرآن',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // When Device Preview is active it injects the simulated locale and
      // MediaQuery; otherwise we fall back to Arabic.
      locale: DevicePreview.locale(context) ?? const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final wrapped = DevicePreview.appBuilder(context, child);
        // Force RTL globally so Arabic text always flows correctly inside
        // whichever device frame Device Preview is simulating.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: wrapped,
        );
      },
      home: const SurahListScreen(),
    );
  }
}
