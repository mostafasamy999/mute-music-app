import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/data/local/separation_worker.dart';

// Bodies run on the worker isolate, so they are top-level functions.

Future<void> _threeChunks(SeparationJob job, ChunkCallback onChunk) async {
  for (int done = 0; done <= 3; done++) {
    onChunk(done, 3);
  }
}

Future<void> _throws(SeparationJob job, ChunkCallback onChunk) async {
  onChunk(0, 3);
  throw StateError('model failed to load');
}

/// Stands in for the OS killing the worker: no result is ever sent. Also
/// proves the body runs on its own isolate — killing this one would end the
/// test run otherwise.
Future<void> _dies(SeparationJob job, ChunkCallback onChunk) async {
  onChunk(0, 3);
  Isolate.current.kill(priority: Isolate.immediate);
  await Future<void>.delayed(const Duration(seconds: 5));
}

void main() {
  const SeparationJob job = SeparationJob(
    inputPcmPath: '/tmp/in.pcm',
    sampleRate: 44100,
    channels: 2,
    modelPath: '/tmp/model.onnx',
    outputPcmPath: '/tmp/out.pcm',
  );

  test('forwards every chunk, in order, then completes', () async {
    final List<(int, int)> chunks = <(int, int)>[];

    await const SeparationWorker(
      _threeChunks,
    ).run(job, onChunk: (int done, int total) => chunks.add((done, total)));

    expect(chunks, <(int, int)>[(0, 3), (1, 3), (2, 3), (3, 3)]);
  });

  test('a body that throws completes with a SeparationException', () async {
    await expectLater(
      const SeparationWorker(_throws).run(job, onChunk: (_, _) {}),
      throwsA(
        isA<SeparationException>().having(
          (SeparationException e) => e.message,
          'message',
          contains('model failed to load'),
        ),
      ),
    );
  });

  test('a worker that dies without a result still completes', () async {
    await expectLater(
      const SeparationWorker(_dies).run(job, onChunk: (_, _) {}),
      throwsA(isA<SeparationException>()),
    ).timeout(const Duration(seconds: 3));
  });
}
