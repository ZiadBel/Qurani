// ============================================================================
// Scroll-through and interaction verification.
//
// 1. Scrolls long surahs (Al-Kahf, Al-Baqarah) from start to end and asserts
//    no overflow / layout exception is raised at any scroll position.
//    Captures one PNG at the start, middle, and end of each surah for manual
//    inspection.
// 2. Drives the long-press bookmark gesture on the reading screen and verifies
//    that SharedPreferences receives the expected values and the SnackBar
//    appears without layout error.
//
// Quran text is read-only — these tests never write to the JSON asset.
// ============================================================================
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurani/data/bookmark_service.dart';
import 'package:qurani/ui/surah_reading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localizationsDelegates = <LocalizationsDelegate<Object>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _kCaptureKey = ValueKey('_capture_root');

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

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
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

MaterialApp _testApp(Widget home) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: _localizationsDelegates,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B5E20),
      ).copyWith(
        textTheme:
            ThemeData(useMaterial3: true).textTheme.apply(fontFamily: 'Amiri'),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );

/// Walks through every page of [surahNumber] by simulating a swipe at the
/// PageView, asserting that no overflow / layout error fires on any page.
/// Captures PNGs at the start, midpoint, and end.
Future<List<FlutterErrorDetails>> _flipThroughSurah(
  WidgetTester tester,
  int surahNumber,
  String label, {
  required Size deviceSize,
  required double dpr,
}) async {
  await tester.binding.setSurfaceSize(deviceSize);
  tester.view.physicalSize = deviceSize * dpr;
  tester.view.devicePixelRatio = dpr;

  final caught = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = caught.add;

  try {
    await tester.pumpWidget(
      RepaintBoundary(
        key: _kCaptureKey,
        child: _testApp(SurahReadingScreen(surahNumber: surahNumber)),
      ),
    );
    // Let the asset load and the paginator run.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    await _saveScreenshot(
      tester,
      'build/device_preview_screens/scroll/${label}__start.png',
    );

    final pageView = find.byKey(const ValueKey('mushaf_pageview'));
    expect(pageView, findsOneWidget,
        reason: 'Reading screen should contain the Mushaf PageView');

    final controller = (tester.widget<PageView>(pageView)).controller!;
    // Resolve total pages from the PageController's attached position.
    // We don't have direct access to MushafPaginator output here; we infer
    // total pages by reading PageMetrics.maxScrollExtent / viewportDimension.
    final position = controller.position;
    final totalPages =
        ((position.maxScrollExtent / position.viewportDimension).round() + 1);
    expect(totalPages, greaterThanOrEqualTo(1));

    // Animate page-by-page through the surah.
    var midpointCaptured = false;
    for (var p = 1; p < totalPages; p++) {
      controller.animateToPage(p,
          duration: const Duration(milliseconds: 50), curve: Curves.linear);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 100));
      if (!midpointCaptured && p >= totalPages ~/ 2) {
        await _saveScreenshot(
          tester,
          'build/device_preview_screens/scroll/${label}__mid.png',
        );
        midpointCaptured = true;
      }
    }
    await _saveScreenshot(
      tester,
      'build/device_preview_screens/scroll/${label}__end.png',
    );

    return caught;
  } finally {
    FlutterError.onError = previous;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  }
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

  // Scroll-through tests use a representative phone size; the device-size
  // tests already cover layout at every size.
  const phone = Size(390, 844);
  const dpr = 3.0;

  testWidgets('Flip through Surah Al-Kahf pages (110 ayahs) — no overflow',
      (tester) async {
    final errs = await _flipThroughSurah(
      tester,
      18,
      'kahf',
      deviceSize: phone,
      dpr: dpr,
    );
    final overflows = errs
        .where((e) => e.exception.toString().toLowerCase().contains('overflow'))
        .toList();
    expect(overflows, isEmpty,
        reason: 'Overflow while paging through Al-Kahf:\n'
            '${overflows.map((e) => e.exception).join('\n')}');
  });

  testWidgets('Flip through Surah Al-Baqarah pages (286 ayahs) — no overflow',
      (tester) async {
    final errs = await _flipThroughSurah(
      tester,
      2,
      'baqarah',
      deviceSize: phone,
      dpr: dpr,
    );
    final overflows = errs
        .where((e) => e.exception.toString().toLowerCase().contains('overflow'))
        .toList();
    expect(overflows, isEmpty,
        reason: 'Overflow while paging through Al-Baqarah:\n'
            '${overflows.map((e) => e.exception).join('\n')}');
  });

  testWidgets('Horizontal swipe on the reading panel changes pages',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(phone);
    tester.view.physicalSize = phone * dpr;
    tester.view.devicePixelRatio = dpr;
    try {
      // Use Al-Kahf so we have many pages to swipe through.
      await tester.pumpWidget(
        _testApp(const SurahReadingScreen(surahNumber: 18)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      final pageView = tester.widget<PageView>(
        find.byKey(const ValueKey('mushaf_pageview')),
      );
      final controller = pageView.controller!;
      final startPage = controller.page!.round();

      // Swipe horizontally inside the reading panel. RTL PageView has
      // reverse: true, so a leftward drag should move FORWARD a page.
      final gestureCenter = tester.getCenter(
        find.byKey(const ValueKey('mushaf_gesture')),
      );
      // Negative dx = drag from right to left (forward in RTL).
      await tester.dragFrom(gestureCenter, const Offset(-300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));

      expect(controller.page!.round(), greaterThan(startPage),
          reason: 'A horizontal swipe on the panel must advance the page; '
              'the long-press gesture must not capture horizontal drags. '
              '(start=$startPage, after-swipe=${controller.page!.round()})');
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Opening Al-Baqarah at initialAyah=200 restores the right page',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(phone);
    tester.view.physicalSize = phone * dpr;
    tester.view.devicePixelRatio = dpr;
    try {
      await tester.pumpWidget(
        _testApp(const SurahReadingScreen(surahNumber: 2, initialAyah: 200)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      final pageView = tester.widget<PageView>(
        find.byKey(const ValueKey('mushaf_pageview')),
      );
      final controller = pageView.controller!;
      // After mount + post-frame jump-to-page, the controller should NOT be
      // on page 0 (since ayah 200 cannot fit on the first page of Al-Baqarah).
      expect(controller.page!.round(), greaterThan(0),
          reason: 'Restore-to-last-read should jump past page 0 when '
              'initialAyah is deep into the surah.');
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets(
      'Lazy paginator extends past the initial surahs as the user nears the tail',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(phone);
    tester.view.physicalSize = phone * dpr;
    tester.view.devicePixelRatio = dpr;
    try {
      // Open Al-Baqarah; initial paginated slice is [surah 2, surah 3].
      // Jump near the tail of that slice — lazy extension should kick in
      // and the page count should grow to cover surah 4 too.
      await tester.pumpWidget(
        _testApp(const SurahReadingScreen(surahNumber: 2)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final pageView0 = tester.widget<PageView>(
          find.byKey(const ValueKey('mushaf_pageview')));
      final controller = pageView0.controller!;
      final initialItemCount =
          pageView0.childrenDelegate.estimatedChildCount!;

      // Jump near the tail to trigger lazy extension.
      controller.jumpToPage(initialItemCount - 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      final newItemCount = tester
          .widget<PageView>(find.byKey(const ValueKey('mushaf_pageview')))
          .childrenDelegate
          .estimatedChildCount!;
      expect(newItemCount, greaterThan(initialItemCount),
          reason: 'Page count must grow as the user nears the tail. '
              'initial=$initialItemCount, after-jump=$newItemCount');
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Long-press on an ayah saves bookmark and shows SnackBar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(phone);
    tester.view.physicalSize = phone * dpr;
    tester.view.devicePixelRatio = dpr;

    final caught = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = caught.add;

    try {
      await tester.pumpWidget(
        RepaintBoundary(
          key: _kCaptureKey,
          // Use Surah 1 (Al-Fatihah, 7 ayahs) so the target ayah is on screen
          // without any scrolling. Start at ayah 7 so any later mark to a
          // different ayah is observably different from the initial save.
          child: _testApp(
            const SurahReadingScreen(surahNumber: 1, initialAyah: 7),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The new Mushaf-style reading screen wraps the paragraph in a
      // GestureDetector(key: 'mushaf_gesture') that hit-tests the long-press
      // location to find the containing ayah. Press near the top-right (RTL
      // start of text) so we land on ayah 1 or 2.
      final gestureFinder = find.byKey(const ValueKey('mushaf_gesture'));
      expect(gestureFinder, findsOneWidget,
          reason: 'Reading screen should contain the Mushaf GestureDetector');
      final rtBox = tester.getRect(gestureFinder);
      // Press well inside the panel, near the top-right corner so RTL hits ayah 1.
      final pressPoint = Offset(rtBox.right - 40, rtBox.top + 50);
      await tester.longPressAt(pressPoint);
      // Let the gesture, the async bookmark save, and the SnackBar entrance
      // animation all advance. SnackBar enter animation is ~150ms.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 500));

      // Bookmark should be persisted via SharedPreferences. We initialised
      // the screen with initialAyah=7, so the long-press must move it to a
      // SMALLER index (one of ayahs 1-6, since we pressed near the top of the
      // paragraph). This proves the long-press actually fired and is not just
      // reading the initState save.
      final bookmark = await BookmarkService.instance.read();
      expect(bookmark, isNotNull,
          reason: 'Long-press should persist a bookmark');
      expect(bookmark!.surah, 1);
      expect(bookmark.ayah, lessThan(7),
          reason: 'Long-press near the top must have re-marked the bookmark '
              'to an earlier ayah (initial was 7).');

      // SnackBar should be visible.
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'SnackBar should appear after long-press');

      await _saveScreenshot(
        tester,
        'build/device_preview_screens/scroll/long_press_snackbar.png',
      );

      final overflows = caught
          .where(
              (e) => e.exception.toString().toLowerCase().contains('overflow'))
          .toList();
      expect(overflows, isEmpty,
          reason: 'Overflow during long-press:\n'
              '${overflows.map((e) => e.exception).join('\n')}');
    } finally {
      FlutterError.onError = previous;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });
}
