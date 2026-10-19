import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/removal_step_tile.dart';

/// "Remove music only" as a list of steps, so the user sees which stage the
/// job is in instead of one percentage that sits at 0% and 100%.
class RemovalSteps extends StatelessWidget {
  const RemovalSteps({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, RemovalProgress?>(
        selector: (MuteVideoState state) => state.removal,
        builder: (BuildContext context, RemovalProgress? progress) {
          if (progress == null) return const SizedBox.shrink();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final RemovalStep step in RemovalStep.values)
                RemovalStepTile(
                  label: _label(context, step),
                  look: _look(step, progress.step),
                  detail: step == progress.step
                      ? _detail(context, progress)
                      : null,
                  fraction: step == progress.step ? _fraction(progress) : null,
                ),
            ],
          );
        },
      );

  RemovalStepLook _look(RemovalStep step, RemovalStep current) =>
      step.index < current.index
      ? RemovalStepLook.done
      : step == current
      ? RemovalStepLook.active
      : RemovalStepLook.waiting;

  String _label(BuildContext context, RemovalStep step) => switch (step) {
    RemovalStep.model => S.of(context).stepModel,
    RemovalStep.extract => S.of(context).stepExtract,
    RemovalStep.separate => S.of(context).stepSeparate,
    RemovalStep.build => S.of(context).stepBuild,
  };

  String? _detail(BuildContext context, RemovalProgress progress) {
    if (progress.total == 0) return null;
    return switch (progress.step) {
      // The part being worked on, not the last one finished.
      RemovalStep.separate =>
        S
            .of(context)
            .stepPart(
              (progress.done + 1).clamp(1, progress.total),
              progress.total,
            ),
      RemovalStep.model when progress.done > 0 =>
        S.of(context).stepPercent(progress.done),
      _ => null,
    };
  }

  /// A download that hasn't reported yet (or isn't needed) spins rather than
  /// sitting at an empty bar.
  double? _fraction(RemovalProgress progress) =>
      progress.step == RemovalStep.model && progress.done == 0
      ? null
      : progress.fraction;
}
