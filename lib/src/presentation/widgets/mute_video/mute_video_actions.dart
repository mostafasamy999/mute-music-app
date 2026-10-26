import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/convert_to_audio_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/remove_music_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/remove_sound_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/save_video_button.dart';

/// Only the actions that make sense for the current file (spec 006 §3, §3.1).
/// The state decides which ones; each button still owns its enabled rules.
class MuteVideoActions extends StatelessWidget {
  const MuteVideoActions({super.key});

  /// Actions whose feature isn't built yet stay hidden until their plan step
  /// lands: Save to Music (S11), Extract text (S12),
  /// and Remove music on a sound file (S13).
  static const Set<MediaAction> built = <MediaAction>{
    MediaAction.removeSound,
    MediaAction.removeMusic,
    MediaAction.convertToAudio,
    MediaAction.saveToGallery,
  };

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MuteVideoCubit, MuteVideoState>(
        buildWhen: (MuteVideoState previous, MuteVideoState current) =>
            !listEquals(previous.actions, current.actions),
        builder: (BuildContext context, MuteVideoState state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final MediaAction action in state.actions)
              if (_isBuilt(action, state.current?.kind)) ...<Widget>[
                _button(action),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      );

  /// Remove music only on a sound file needs its own audio-only ends (S13);
  /// the video pipeline can't mux without a video track.
  static bool _isBuilt(MediaAction action, MediaKind? kind) =>
      built.contains(action) &&
      !(action == MediaAction.removeMusic && kind == MediaKind.audio);

  Widget _button(MediaAction action) => switch (action) {
    MediaAction.removeSound => const RemoveSoundButton(),
    MediaAction.removeMusic => const RemoveMusicButton(),
    MediaAction.convertToAudio => const ConvertToAudioButton(),
    MediaAction.saveToGallery => const SaveVideoButton(),
    // Hidden by [built] until their steps land.
    MediaAction.extractText ||
    MediaAction.saveToMusic => const SizedBox.shrink(),
  };
}
