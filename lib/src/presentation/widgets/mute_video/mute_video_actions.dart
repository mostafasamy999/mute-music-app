import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/choose_part_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/more_actions_toggle.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/pick_video_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/remove_music_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/remove_sound_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/save_video_button.dart';

enum _Action { pick, choosePart, removeMusic, removeSound, save }

/// Only the next sensible actions, plus a toggle for the rest. Each button
/// still owns its own enabled rules.
class MuteVideoActions extends StatefulWidget {
  const MuteVideoActions({super.key});

  @override
  State<MuteVideoActions> createState() => _MuteVideoActionsState();
}

class _MuteVideoActionsState extends State<MuteVideoActions> {
  bool _expanded = false;

  /// The default set per stage. Expanded shows every action, in this order.
  static const Map<ActionStage, List<_Action>> _defaults =
      <ActionStage, List<_Action>>{
        ActionStage.empty: <_Action>[_Action.pick],
        ActionStage.picked: <_Action>[_Action.pick, _Action.removeMusic],
        ActionStage.done: <_Action>[_Action.pick, _Action.save],
      };

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MuteVideoCubit, MuteVideoState>(
        // A new stage means a new obvious next step: fold the rest away.
        listenWhen: (MuteVideoState previous, MuteVideoState current) =>
            previous.stage != current.stage,
        listener: (_, _) => setState(() => _expanded = false),
        buildWhen: (MuteVideoState previous, MuteVideoState current) =>
            previous.stage != current.stage,
        builder: (BuildContext context, MuteVideoState state) =>
            _buildActions(state.stage),
      );

  Widget _buildActions(ActionStage stage) {
    final List<_Action> shown = _expanded
        ? _Action.values
        : _defaults[stage]!;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: AlignmentDirectional.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final _Action action in shown) ...<Widget>[
            _button(action),
            const SizedBox(height: AppSpacing.sm),
          ],
          MoreActionsToggle(
            expanded: _expanded,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
    );
  }

  Widget _button(_Action action) => switch (action) {
    _Action.pick => const PickVideoButton(),
    _Action.choosePart => const ChoosePartButton(),
    _Action.removeMusic => const RemoveMusicButton(),
    _Action.removeSound => const RemoveSoundButton(),
    _Action.save => const SaveVideoButton(),
  };
}
