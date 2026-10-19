import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';
import 'package:mute_music_app/src/data/local/music_separator.dart';

/// Everything the worker needs, as plain values. Audio never crosses the
/// isolate boundary — the worker reads and writes the PCM files itself.
class SeparationJob {
  const SeparationJob({
    required this.inputPcmPath,
    required this.sampleRate,
    required this.channels,
    required this.modelPath,
    required this.outputPcmPath,
  });

  final String inputPcmPath;
  final int sampleRate;
  final int channels;
  final String modelPath;
  final String outputPcmPath;
}

typedef ChunkCallback = void Function(int done, int total);

/// The work done inside the isolate. Swappable so tests can drive the isolate
/// plumbing without the model.
typedef SeparationBody =
    Future<void> Function(SeparationJob job, ChunkCallback onChunk);

/// Reads the track, runs the model over it and writes the voices back out.
Future<void> separateTrack(SeparationJob job, ChunkCallback onChunk) async {
  final StereoAudio input = PcmIo.read(
    File(job.inputPcmPath),
    job.sampleRate,
    job.channels,
  );
  final StereoAudio voice = await MusicSeparator().separate(
    modelPath: job.modelPath,
    input: input,
    onProgress: onChunk,
  );
  PcmIo.write(File(job.outputPcmPath), voice.left, voice.right);
}

/// Runs [SeparationBody] on its own isolate so the UI keeps drawing.
///
/// Not `compute()`: that returns one value at the end, and the screen needs
/// a progress update per chunk. One isolate per job; it exits when done.
class SeparationWorker {
  const SeparationWorker([this._body = separateTrack]);

  final SeparationBody _body;

  Future<void> run(SeparationJob job, {required ChunkCallback onChunk}) async {
    final ReceivePort port = ReceivePort();
    final Completer<void> finished = Completer<void>();
    port.listen((Object? message) {
      if (finished.isCompleted) return;
      switch (message) {
        case _Chunk(:final int done, :final int total):
          onChunk(done, total);
        case _Done():
          finished.complete();
        case _Failed(:final String error):
          finished.completeError(SeparationException(error));
        // An uncaught error (onError) or an exit with no result (onExit, e.g.
        // the OS killed it) must still end the job, or the screen stays busy.
        case [final Object? error, _]:
          finished.completeError(SeparationException('$error'));
        default:
          finished.completeError(
            const SeparationException('worker exited without a result'),
          );
      }
    });

    try {
      await Isolate.spawn<_Start>(
        _main,
        _Start(job, port.sendPort, RootIsolateToken.instance, _body),
        onError: port.sendPort,
        onExit: port.sendPort,
      );
      await finished.future;
    } finally {
      port.close();
    }
  }
}

class SeparationException implements Exception {
  const SeparationException(this.message);

  final String message;

  @override
  String toString() => 'SeparationException: $message';
}

class _Start {
  const _Start(this.job, this.port, this.token, this.body);

  final SeparationJob job;
  final SendPort port;
  final RootIsolateToken? token;
  final SeparationBody body;
}

class _Chunk {
  const _Chunk(this.done, this.total);

  final int done;
  final int total;
}

class _Done {
  const _Done();
}

class _Failed {
  const _Failed(this.error);

  final String error;
}

Future<void> _main(_Start start) async {
  // The model runtime talks to native code over a platform channel, which a
  // background isolate can only use once it is tied to the root isolate.
  final RootIsolateToken? token = start.token;
  if (token != null) BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  Object result;
  try {
    await start.body(
      start.job,
      (int done, int total) => start.port.send(_Chunk(done, total)),
    );
    result = const _Done();
  } on Object catch (error) {
    result = _Failed('$error');
  }
  // Exit explicitly: open platform-channel ports would otherwise keep the
  // isolate alive after the job.
  Isolate.exit(start.port, result);
}
