/// Qurani User-Facing String Constants — Single Source of Truth
/// ZERO hardcoded user-facing strings outside this file and l10n ARB files.
/// For localized strings, use AppLocalizations (generated from ARB).
/// This file holds non-localized technical strings only.
class AppStrings {
  AppStrings._();

  // ── App Identity ──
  static const String appName = 'Qurani';
  static const String appNameAr = 'قرآني';
  static const String publisher = 'Ziad';
  // Upstream attribution preserved for MIT compliance — surfaced via the About screen.
  static const String originalProject = 'Al-Furkan (Idris Ghamid & IDRISIUM Corp.)';
  static const String tagline = 'A free Quran app — sadaqah jariyah';

  // ── URLs ──
  // TODO: replace with your real support email / website before publishing.
  static const String supportEmail = 'support@example.com';
  static const String upstreamRepo =
      'https://github.com/IDRISIUMCorp/al-furkan-quran-flutter-app';

  // ── Data Source Attribution ──
  static const String quranDataSource = 'Tanzil.net';
  static const String quranDataVersion = 'v1.1 (Uthmanic)';
  static const String prayerTimeApi = 'Aladhan.com';

  // ── Error Messages (fallback — prefer l10n for user-facing) ──
  static const String errorNetwork = 'No internet connection';
  static const String errorTimeout = 'Request timed out';
  static const String errorServer = 'Server error occurred';
  static const String errorUnknown = 'An unexpected error occurred';
  static const String errorDataIntegrity =
      'Data integrity check failed — resource may be corrupted';

  // ── Notification Channel ──
  // Channel id renamed to align with the Qurani identity. Pre-release, so no
  // legacy users to migrate.
  static const String notificationChannelId = 'qurani_notifications';
  static const String notificationChannelName = 'Qurani Notifications';

  // ── Hive Box Names ──
  static const String hiveBoxUser = 'user';
  static const String hiveBoxPinned = 'pinned';
  static const String hiveBoxNotes = 'notes';

  // ── Hive Data Keys ──
  static const String hiveKeySurahs = 'surahs_data';
  static const String hiveKeyBookmarks = 'bookmarks_data';
  static const String hiveKeyNotes = 'notes_data';

  // ── Shared Preferences Keys ──
  static const String prefFirstRun = 'qurani_first_run_defaults_applied';
  static const String prefLanguageCode = 'selectedLanguageCode';
  static const String prefThemeMode = 'app_theme_mode';
  static const String prefsKeyLastPage = 'last_page';
  static const String prefsKeyLastAyahKey = 'last_ayah_key';

  // ── Route Names ──
  static const String routeHome = '/';
  static const String routeScript = '/script';
  static const String routeSearch = '/search';
  static const String routePrayer = '/prayer';
  static const String routeQibla = '/qibla';
  static const String routeAzkar = '/azkar';
  static const String routeSunnah = '/sunnah';
  static const String routeWudu = '/wudu';
  static const String routeSettings = '/settings';
  static const String routeSettingsTheme = '/settings/theme';
  static const String routeSettingsNotifications = '/settings/notifications';
  static const String routeSettingsLanguage = '/settings/language';
  static const String routeAbout = '/about';
  static const String routeBookmarks = '/bookmarks';
  static const String routeHifz = '/hifz';
  static const String routeStats = '/stats';
  static const String routeResources = '/resources';
  static const String routeOffline = '/offline';
  static const String routeKhatma = '/khatma';
  static const String routeOnboarding = '/onboarding';
}
