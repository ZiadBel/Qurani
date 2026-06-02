import "package:qurani/src/core/audio/services/audio_playback_service.dart";
import "package:qurani/src/core/di/service_locator.dart";

AudioPlaybackService get audioPlaybackService => getIt<AudioPlaybackService>();
