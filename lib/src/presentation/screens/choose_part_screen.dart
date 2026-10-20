import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/constants/clip_limits.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/presentation/widgets/choose_part/part_length_hint.dart';
import 'package:mute_music_app/src/presentation/widgets/choose_part/part_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/choose_part/part_range_slider.dart';
import 'package:mute_music_app/src/presentation/widgets/choose_part/part_time_labels.dart';
import 'package:video_player/video_player.dart';

/// What the Choose a part screen opens with.
class ChoosePartArgs {
  const ChoosePartArgs({required this.path, this.initial});

  /// The original video. A part is always cut from the original.
  final String path;

  /// The last range used on this original, if any.
  final ClipRange? initial;
}

/// Lets the user pick a time range of the original (spec 003 §4). Pops with
/// the chosen [ClipRange], or with nothing when the user goes back.
///
/// Owns the player controller, so it is stateful, but every value the build
/// reads lives in a ValueNotifier instead of setState.
class ChoosePartScreen extends StatefulWidget {
  const ChoosePartScreen({required this.args, super.key});

  final ChoosePartArgs args;

  @override
  State<ChoosePartScreen> createState() => _ChoosePartScreenState();
}

class _ChoosePartScreenState extends State<ChoosePartScreen> {
  final ValueNotifier<VideoPlayerController?> _controller =
      ValueNotifier<VideoPlayerController?>(null);
  final ValueNotifier<bool> _failed = ValueNotifier<bool>(false);
  late final ValueNotifier<ClipRange> _range;

  @override
  void initState() {
    super.initState();
    _range = ValueNotifier<ClipRange>(
      widget.args.initial ??
          ClipRange(start: Duration.zero, end: ClipLimits.minPartLength),
    );
    _load();
  }

  @override
  void dispose() {
    _controller.value?.removeListener(_keepInRange);
    _controller.value?.dispose();
    _controller.dispose();
    _failed.dispose();
    _range.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final VideoPlayerController next = VideoPlayerController.file(
      File(widget.args.path),
    );
    try {
      await next.initialize();
    } on Object {
      await next.dispose();
      if (mounted) _failed.value = true;
      return;
    }
    if (!mounted) return next.dispose();
    _range.value = _initialRange(next.value.duration);
    await next.seekTo(_range.value.start);
    next.addListener(_keepInRange);
    _controller.value = next;
  }

  /// The last range when it still fits, otherwise the whole video.
  ClipRange _initialRange(Duration duration) {
    final ClipRange? last = widget.args.initial;
    if (last != null && last.end <= duration) return last;
    return ClipRange(start: Duration.zero, end: duration);
  }

  /// Plays only the chosen range, looping back to the start handle.
  void _keepInRange() {
    final VideoPlayerController? controller = _controller.value;
    if (controller == null || !controller.value.isPlaying) return;
    final Duration position = controller.value.position;
    if (position >= _range.value.end || controller.value.isCompleted) {
      controller.seekTo(_range.value.start);
    }
  }

  Future<void> _togglePlay() async {
    final VideoPlayerController? controller = _controller.value;
    if (controller == null) return;
    if (controller.value.isPlaying) return controller.pause();
    final Duration position = controller.value.position;
    if (position < _range.value.start || position >= _range.value.end) {
      await controller.seekTo(_range.value.start);
    }
    await controller.play();
  }

  /// Shows the frame under the handle that moved, so the user sees where
  /// they are cutting.
  void _onRangeChanged(ClipRange next) {
    final VideoPlayerController? controller = _controller.value;
    final bool startMoved = next.start != _range.value.start;
    _range.value = next;
    if (controller == null) return;
    controller
      ..pause()
      ..seekTo(startMoved ? next.start : next.end);
  }

  void _submit() => Navigator.of(context).pop(_range.value);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(S.of(context).choosePartTitle)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: ValueListenableBuilder<VideoPlayerController?>(
          valueListenable: _controller,
          builder:
              (BuildContext context, VideoPlayerController? controller, _) =>
                  Column(
                    children: <Widget>[
                      Expanded(
                        child: PartPreview(
                          controller: controller,
                          failed: _failed,
                          onTap: _togglePlay,
                        ),
                      ),
                      if (controller != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        PartRangeSlider(
                          range: _range,
                          duration: controller.value.duration,
                          onChanged: _onRangeChanged,
                        ),
                        PartTimeLabels(range: _range),
                        PartLengthHint(range: _range),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: controller == null ? null : _submit,
                        icon: const Icon(Icons.check),
                        label: Text(S.of(context).usePart),
                      ),
                    ],
                  ),
        ),
      ),
    ),
  );
}
