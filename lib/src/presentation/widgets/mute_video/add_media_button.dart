import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/add_media_sheet.dart';

/// The only widget on the empty screen: a large add icon in the center
/// (spec 006 §2.1). Tapping it asks for the kind, then opens its picker.
class AddMediaButton extends StatelessWidget {
  const AddMediaButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) => state.isBusy,
        builder: (BuildContext context, bool busy) {
          final ColorScheme scheme = Theme.of(context).colorScheme;
          return Material(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: busy ? null : () => _add(context),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    busy
                        ? const CircularProgressIndicator()
                        : Icon(
                            Icons.add_circle_outline,
                            size: 72,
                            color: scheme.primary,
                          ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      S.of(context).addFileHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Future<void> _add(BuildContext context) async {
    final MuteVideoCubit cubit = context.read<MuteVideoCubit>();
    final MediaKind? kind = await AddMediaSheet.show(context);
    if (kind != null) await cubit.addMedia(kind);
  }
}
