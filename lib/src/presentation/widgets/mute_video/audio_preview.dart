import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/extensions/duration_extensions.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/original_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/player_host.dart';
import 'package:video_player/video_player.dart';

/// Plays a local sound file: play/pause, a seek bar and the time
/// (spec 006 §2.2).
class AudioPreview extends StatelessWidget {
  const AudioPreview({
    required this.path,
    this.startAt = Duration.zero,
    this.onOriginal,
    super.key,
  });

  final String path;
  final Duration startAt;

  /// When set, shows the original icon (spec 006 §3.2).
  final ValueChanged<Duration>? onOriginal;

  @override
  Widget build(BuildContext context) => PlayerHost(
    path: path,
    startAt: startAt,
    builder: (VideoPlayerController controller) =>
        _AudioControls(controller: controller, onOriginal: onOriginal),
  );
}

class _AudioControls extends StatelessWidget {
  const _AudioControls({required this.controller, this.onOriginal});

  final VideoPlayerController controller;
  final ValueChanged<Duration>? onOriginal;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (BuildContext context, VideoPlayerValue value, _) {
          final int total = value.duration.inMilliseconds;
          final int at = value.position.inMilliseconds.clamp(0, total);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.graphic_eq, size: 96, color: scheme.primary),
                const SizedBox(height: AppSpacing.md),
                // Time runs left to right in both languages, like the cut
                // screen's slider (003 §4).
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    children: <Widget>[
                      Slider(
                        max: total > 0 ? total.toDouble() : 1,
                        value: total > 0 ? at.toDouble() : 0,
                        onChanged: total > 0
                            ? (double ms) => controller.seekTo(
                                Duration(milliseconds: ms.round()),
                              )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(value.position.clock),
                            Text(value.duration.clock),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (onOriginal
                        case final ValueChanged<Duration> open) ...<Widget>[
                      OriginalButton(controller: controller, onOriginal: open),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    IconButton.filled(
                      iconSize: 40,
                      onPressed: () => value.isPlaying
                          ? controller.pause()
                          : controller.play(),
                      icon: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
