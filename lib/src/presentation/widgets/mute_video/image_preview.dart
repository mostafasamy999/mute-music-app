import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/preview_unavailable.dart';

/// Shows a local image, fitted inside the preview area (spec 006 §2.2).
class ImagePreview extends StatelessWidget {
  const ImagePreview({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.radius),
    child: Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const PreviewUnavailable(),
    ),
  );
}
