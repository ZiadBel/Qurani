// ============================================================================
// Device-size UI verification harness.
//
// This is a development-time check that pumps the real screens at the exact
// pixel sizes Device Preview would simulate. It:
//   - asserts no FlutterError (overflow, layout assertion failure) fires;
//   - writes PNG screenshots under build/device_preview_screens/ for manual
//     inspection of RTL alignment, font rendering, and clipping;
//   - runs against the real QuranRepository against the bundled asset.
//
// These checks do not touch Quran text. They only exercise the UI surface
// at multiple sizes.
// ============================================================================
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurani/ui/surah_list_screen.dart';
import 'package:qurani/ui/surah_reading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localizationsDelegates = <LocalizationsDelegate<Object>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class _Device {
  final String name;
  final Size size; // logical pixels
  final double dpr;
  const _Device(this.name, this.size, this.dpr);
}

const _devices = <_Device>[
  // Small Android phone (e.g. Pixel 4a-ish)
  _Device('small_android', Size(360, 640), 2.0),
  // Large Android phone (e.g. Pixel 7 Pro-ish)
  _Device('large_android', Size(412, 915), 3.0),
  // iPhone (iPhone 14)
  _Device('iphone', Size(390, 844), 3.0),
  // Tablet (iPad-ish) portrait
  _Device('tablet_portrait', Size(820, 1180), 2.0),
  // Tablet landscape
  _Device('tablet_landscape', Size(1180, 820), 2.0),
];

Future<void> _bindAssetMessenger() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    final f = File(key);
    if (f.existsSync()) {
      return ByteData.view(f.readAsBytesSync().buffer);
    }
    return null;
  });
}

Future<void> _saveScreenshot(WidgetTester tester, String path) async {
  final boundaryFinder = find.byKey(_kCaptureKey);
  if (boundaryFinder.evaluate().isEmpty) return;
  final boundary = tester.renderObject(boundaryFinder) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

const _kCaptureKey = ValueKey('_capture_root');

Future<void> _runOnDevice(
  WidgetTester tester,
  _Device d,
  Widget Function() build,
  String label,
) async {
  await tester.binding.setSurfaceSize(d.size);
  tester.view.physicalSize = d.size * d.dpr;
  tester.view.devicePixelRatio = d.dpr;

  // Capture all FlutterError reports so we can search for overflow / layout
  // assertion warnings later. We forward them to the default handler so the
  // test framework still sees them.
  final caughtErrors = <FlutterErrorDetails>[];
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    caughtErrors.add(details);
  };
  try {
    await tester.pumpWidget(
      RepaintBoundary(key: _kCaptureKey, child: build()),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 200));

    await _saveScreenshot(
      tester,
      'build/device_preview_screens/${label}__${d.name}.png',
    );

    final overflows = caughtErrors
        .where((e) => e.exception.toString().toLowerCase().contains('overflow'))
        .toList();
    expect(
      overflows,
      isEmpty,
      reason: 'Overflow on ${d.name} / $label:\n'
          '${overflows.map((e) => e.exception).join('\n')}',
    );
    final layoutAsserts = caughtErrors
        .where((e) {
          final s = e.exception.toString().toLowerCase();
          return s.contains('renderflex') ||
              s.contains('layout') && s.contains('infinite');
        })
        .toList();
    expect(
      layoutAsserts,
      isEmpty,
      reason: 'Layout errors on ${d.name} / $label:\n'
          '${layoutAsserts.map((e) => e.exception).join('\n')}',
    );
  } finally {
    FlutterError.onError = previousHandler;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  }
}

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _bindAssetMessenger();
    SharedPreferences.setMockInitialValues({});
    await _loadFont('AmiriQuran', 'assets/fonts/AmiriQuran.ttf');
    await _loadFont('Amiri', 'assets/fonts/Amiri-Regular.ttf');
    final mat = File(
      '${Platform.environment['HOME']}/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (mat.existsSync()) {
      await _loadFont('MaterialIcons', mat.path);
    }
  });

  ThemeData buildTheme(Brightness b) {
    final t = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1B5E20),
      brightness: b,
    );
    return t.copyWith(textTheme: t.textTheme.apply(fontFamily: 'Amiri'));
  }

  MaterialApp testApp(
    Widget home, {
    Brightness brightness = Brightness.light,
    double textScale = 1.0,
  }) =>
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: _localizationsDelegates,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: home,
      );

  for (final d in _devices) {
    testWidgets('Surah list — ${d.name}', (tester) async {
      await _runOnDevice(
        tester,
        d,
        () => testApp(const SurahListScreen()),
        'surah_list',
      );
    });

    testWidgets('Surah reading (Al-Fatihah) — ${d.name}', (tester) async {
      await _runOnDevice(
        tester,
        d,
        () => testApp(const SurahReadingScreen(surahNumber: 1)),
        'reading_surah_1',
      );
    });

    testWidgets('Surah reading (Al-Kahf) — ${d.name}', (tester) async {
      await _runOnDevice(
        tester,
        d,
        () => testApp(const SurahReadingScreen(surahNumber: 18)),
        'reading_surah_18',
      );
    });

    testWidgets('Surah list with bookmark — ${d.name}', (tester) async {
      SharedPreferences.setMockInitialValues({
        'last_read_surah': 18,
        'last_read_ayah': 10,
      });
      await _runOnDevice(
        tester,
        d,
        () => testApp(const SurahListScreen()),
        'surah_list_with_bookmark',
      );
      // Reset so subsequent tests start clean.
      SharedPreferences.setMockInitialValues({});
    });

    // ----- Dark mode -----
    testWidgets('Surah list dark — ${d.name}', (tester) async {
      await _runOnDevice(
        tester,
        d,
        () => testApp(const SurahListScreen(), brightness: Brightness.dark),
        'surah_list_dark',
      );
    });

    testWidgets('Surah reading (Al-Fatihah) dark — ${d.name}', (tester) async {
      await _runOnDevice(
        tester,
        d,
        () => testApp(
          const SurahReadingScreen(surahNumber: 1),
          brightness: Brightness.dark,
        ),
        'reading_surah_1_dark',
      );
    });

    testWidgets('Surah reading (Al-Kahf) dark — ${d.name}', (tester) async {
      await _runOnDevice(
        tester,
        d,
        () => testApp(
          const SurahReadingScreen(surahNumber: 18),
          brightness: Brightness.dark,
        ),
        'reading_surah_18_dark',
      );
    });

    // ----- Text scale 1.5x and 2.0x -----
    for (final scale in const [1.5, 2.0]) {
      final tag = scale.toString().replaceAll('.', '_');

      testWidgets('Surah list textScale=${scale}x — ${d.name}', (tester) async {
        await _runOnDevice(
          tester,
          d,
          () => testApp(const SurahListScreen(), textScale: scale),
          'surah_list_scale_$tag',
        );
      });

      testWidgets(
        'Surah reading (Al-Fatihah) textScale=${scale}x — ${d.name}',
        (tester) async {
          await _runOnDevice(
            tester,
            d,
            () => testApp(
              const SurahReadingScreen(surahNumber: 1),
              textScale: scale,
            ),
            'reading_surah_1_scale_$tag',
          );
        },
      );
    }
  }
}
