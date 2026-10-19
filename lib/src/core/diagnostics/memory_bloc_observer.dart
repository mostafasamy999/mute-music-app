import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_logger.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';

/// TEMPORARY. Logs memory each time the screen's job moves on (new status,
/// new removal step), so the log shows which step was running when RAM ran out.
class MemoryBlocObserver extends BlocObserver {
  const MemoryBlocObserver(this._logger);

  final MemoryLogger _logger;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final Object? current = change.currentState;
    final Object? next = change.nextState;
    if (current is! MuteVideoState || next is! MuteVideoState) return;
    if (current.status == next.status && !_newStep(current, next)) return;
    final String step = next.removal == null
        ? ''
        : ' ${next.removal!.step.name} ${next.removal!.done}/${next.removal!.total}';
    unawaited(_logger.mark('${next.status.name}$step'));
  }

  /// Every step change and every separated chunk, but not each download
  /// percent — that would be a hundred lines.
  bool _newStep(MuteVideoState current, MuteVideoState next) {
    if (current.removal?.step != next.removal?.step) return true;
    return next.removal?.step == RemovalStep.separate &&
        current.removal?.done != next.removal?.done;
  }
}
