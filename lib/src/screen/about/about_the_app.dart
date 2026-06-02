import 'package:qurani/l10n/app_localizations.dart';
import 'package:qurani/src/theme/controller/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String _appVersion = "الإصدار 1.0.0";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      await PackageInfo.fromPlatform();
    } catch (_) {}
    if (mounted) {
      setState(() => _appVersion = "الإصدار 1.0.0");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeState = context.watch<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = themeState.primary;

    return Scaffold(
      backgroundColor:
          isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 18,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            const Gap(8),

            // ── Brand header ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white : const Color(0xFFFFFDF7),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      "assets/branding/qurani.png",
                      fit: BoxFit.contain,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        curve: Curves.easeOutBack,
                        duration: const Duration(milliseconds: 700),
                      )
                      .fadeIn(),
                  const Gap(20),
                  Text(
                    "قرآني",
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 150)),
                  const Gap(2),
                  Text(
                    "Qurani",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: primary,
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _appVersion,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 250)),
                ],
              ),
            ),

            const Gap(28),

            // ── Mission card (Arabic) ──
            _SectionCard(
              isDark: isDark,
              primary: primary,
              icon: Icons.favorite_rounded,
              titleAr: "عن قرآني",
              titleEn: null,
              body: const [
                _BodyLine(
                  "قرآني تطبيق مجاني لخدمة القرآن الكريم، بدون إعلانات وبدون اشتراكات.",
                ),
                _BodyLine(
                  "تم تطوير هذه النسخة وتخصيصها كمشروع صدقة جارية.",
                ),
              ],
            ).animate().slideY(begin: 0.15).fadeIn(
                  duration: const Duration(milliseconds: 500),
                ),

            const Gap(16),

            // ── Credits / attribution ──
            _SectionCard(
              isDark: isDark,
              primary: primary,
              icon: Icons.menu_book_rounded,
              titleAr: "اعتمادات ومصادر",
              titleEn: null,
              body: [
                _BodyLine(
                  "خط القرآن الكريم QCF v4.",
                  muted: true,
                  isDark: isDark,
                ),
                _BodyLine(
                  "التلاوات بإذن من EveryAyah وTarteel ومؤسسة القرآن.",
                  muted: true,
                  isDark: isDark,
                ),
                _BodyLine(
                  "مواقيت الصلاة عبر Aladhan.com.",
                  muted: true,
                  isDark: isDark,
                ),
                _BodyLine(
                  l10n.dataSourcesNote,
                  muted: true,
                  isDark: isDark,
                ),
              ],
            ).animate().slideY(begin: 0.15).fadeIn(
                  duration: const Duration(milliseconds: 500),
                ),

            const Gap(32),

            // ── Footer ──
            Center(
              child: Text(
                "قرآني — صدقة جارية",
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.primary,
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.body,
  });

  final bool isDark;
  final Color primary;
  final IconData icon;
  final String? titleAr;
  final String? titleEn;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const Gap(10),
              if (titleAr != null)
                Text(
                  titleAr!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              if (titleAr != null && titleEn != null) const Gap(8),
              if (titleEn != null)
                Text(
                  titleEn!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
            ],
          ),
          const Gap(12),
          ...body,
        ],
      ),
    );
  }
}

class _BodyLine extends StatelessWidget {
  const _BodyLine(this.text, {this.muted = false, this.isDark});

  final String text;
  final bool muted;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final darkMode =
        isDark ?? Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: muted ? 13 : 14,
          height: 1.7,
          fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
          color: muted
              ? (darkMode ? Colors.white54 : Colors.black54)
              : (darkMode ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
