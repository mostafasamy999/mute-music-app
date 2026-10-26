import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';

/// Asks which kind of file to add (spec 006 §2.1). Pops with the kind, or
/// null when the user closes the sheet.
class AddMediaSheet extends StatelessWidget {
  const AddMediaSheet({super.key});

  static Future<MediaKind?> show(BuildContext context) =>
      showModalBottomSheet<MediaKind>(
        context: context,
        showDragHandle: true,
        builder: (_) => const AddMediaSheet(),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).addFileTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        _option(
          context,
          MediaKind.image,
          Icons.image_outlined,
          S.of(context).addImage,
        ),
        _option(
          context,
          MediaKind.audio,
          Icons.audiotrack_outlined,
          S.of(context).addSound,
        ),
        _option(
          context,
          MediaKind.video,
          Icons.movie_outlined,
          S.of(context).addVideo,
        ),
      ],
    ),
  );

  Widget _option(
    BuildContext context,
    MediaKind kind,
    IconData icon,
    String label,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    onTap: () => Navigator.of(context).pop(kind),
  );
}
