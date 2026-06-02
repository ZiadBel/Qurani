import "package:qurani/src/core/audio/model/recitation_info_model.dart";
import "package:qurani/src/core/audio/resources/recitations.dart";

List<ReciterInfoModel> getSegmentsSupportedReciters() {
  List<ReciterInfoModel> recitations =
      recitationsInfoList.map((e) => ReciterInfoModel.fromMap(e)).toList();
  recitations =
      recitations
          .map((e) => e.copyWith(supportWordSegmentation: e.segmentsUrl != null))
          .toList();
  return recitations;
}

/// First-run default reciter for the segmented-reciter cubit.
/// Returns Muhammad Ayyoub (the 128 kbps Murattal entry if available, falling
/// back to any other Muhammad Ayyoub entry, and finally to the first reciter
/// in the list if the name has been removed). Used only when no saved
/// selection exists — existing user choices are preserved by the cubit.
ReciterInfoModel getDefaultReciter() {
  final all = getSegmentsSupportedReciters();
  const preferredName = "Muhammad Ayyoub";

  final preferred128 = all.where(
    (r) => r.name == preferredName && r.link.contains("128kbps"),
  );
  if (preferred128.isNotEmpty) return preferred128.first;

  final anyAyyoub = all.where((r) => r.name == preferredName);
  if (anyAyyoub.isNotEmpty) return anyAyyoub.first;

  return all.first;
}
