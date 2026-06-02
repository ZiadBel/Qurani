import "dart:async";

import "package:qurani/l10n/app_localizations.dart";

import "package:qurani/src/screen/quran_script_view/quran_script_view.dart";
import "package:qurani/src/utils/filter/filter_surah.dart";
import "package:qurani/src/utils/number_localization.dart";
import "package:qurani/src/resources/quran_resources/meaning_of_surah.dart";
import "package:qurani/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:qurani/src/theme/values/values.dart";
import "package:qurani/src/widget/components/get_surah_index_widget.dart";



import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:qurani/src/core/navigation/wahy_page_route.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";
import "package:qcf_quran/qcf_quran.dart" as qcf;

import "../../theme/controller/theme_cubit.dart";

class SurahListView extends StatefulWidget {
  final List<SurahInfoModel> surahInfoList;
  final void Function(int page, String ayahKey)? onOpenLocation;

  const SurahListView({
    super.key,
    required this.surahInfoList,
    this.onOpenLocation,
  });

  @override
  State<SurahListView> createState() => _SurahListViewState();
}

class _SurahListViewState extends State<SurahListView> {
  TextEditingController searchController = TextEditingController();

  ScrollController scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    if (surahNameLocalization.isEmpty || surahMeaningLocalization.isEmpty) {
      loadMetaSurah().then((value) => setState(() {}));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Brightness brightness = Theme.of(context).brightness;
    final Color textColor =
        brightness == Brightness.light ? Colors.black : Colors.white;
    final List<SurahInfoModel> filteredSurah = getFilteredSurah(
      context,
      searchController.text.trim(),
    );

    return (surahNameLocalization.isEmpty || surahMeaningLocalization.isEmpty)
        ? const Center(child: CircularProgressIndicator())
        : Scrollbar(
          controller: scrollController,
          radius: Radius.circular(roundedRadius),
          thickness: 13,
          interactive: true,

          child: ListView.builder(
            padding: EdgeInsets.only(
              bottom: 120,
              top: MediaQuery.of(context).padding.top + 3 + 40,
            ),
            itemCount: filteredSurah.length + 1,
            controller: scrollController,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: 5,
                    bottom: 5,
                    left: 5,
                    right: 5,
                  ),
                  child: SearchBar(
                    elevation: WidgetStateProperty.all<double?>(0),
                    hintText: l10n.searchForASurah,
                    controller: searchController,
                    backgroundColor: WidgetStateProperty.all<Color?>(
                      brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF3F4F6),
                    ),
                    leading: const Icon(FluentIcons.search_24_filled),
                    onChanged: (value) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
                );
              }
              final surahIndex = index - 1;

              return Padding(
                padding: const EdgeInsets.only(top: 5, right: 5, left: 5),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(roundedRadius),
                    ),
                    side: BorderSide(
                      color: context.read<ThemeCubit>().state.primaryShade200,
                    ),
                  ),
                  onPressed: () {
                    final onOpen = widget.onOpenLocation;
                    if (onOpen != null) {
                      onOpen(
                        qcf.getPageNumber(filteredSurah[surahIndex].id, 1),
                        "${filteredSurah[surahIndex].id}:1",
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      WahyPageRoute(
                        page: QuranScriptView(
                              startKey: "${filteredSurah[surahIndex].id}:1",
                              endKey:
                                  "${filteredSurah[surahIndex].id}:${filteredSurah[surahIndex].versesCount}",
                            ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 3,
                      bottom: 3,
                    ),
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        getIndexNumberWidget(
                          context,
                          filteredSurah[surahIndex].id,
                          textColor: textColor,
                          height: 40,
                          width: 40,
                        ),
                        const Gap(15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getSurahName(
                                  context,
                                  filteredSurah[surahIndex].id,
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: textColor,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                getSurahRevelationTypeDisplay(
                                      filteredSurah[surahIndex].revelationPlace,
                                    ) ??
                                    getSurahMeaning(
                                      context,
                                      filteredSurah[surahIndex].id,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.2,
                                  color:
                                      brightness == Brightness.light
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "surah${filteredSurah[surahIndex].id.toString().padLeft(3, '0')}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: textColor,
                                    fontFamily: "surah-name-v1",
                                  ),
                                ),
                                if (qcf.isSajdaVerse(filteredSurah[surahIndex].id, 1) ||
                                    qcf.allSajdaVerses.any((s) => s.surah == filteredSurah[surahIndex].id))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      '۩',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.read<ThemeCubit>().state.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              formatAyahCount(
                                context,
                                filteredSurah[surahIndex].versesCount,
                              ),
                              style: TextStyle(
                                color:
                                    brightness == Brightness.light
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
  }


}
