import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/core/constants/model_constants.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/remote/model_download_service.dart';
import 'package:mute_music_app/src/data/repositories/separation_model_repository_impl.dart';

/// Keeps the model out of the real app directory so the test needs no platform.
class _TempStorage extends ModelStorage {
  _TempStorage(this.directory);

  final Directory directory;

  @override
  Future<File> modelFile() async => File('${directory.path}/model.onnx');

  @override
  Future<File> partialFile() async => File('${directory.path}/model.onnx.part');
}

/// Writes [bytes] worth of file instead of hitting the network.
class _FakeDownload extends ModelDownloadService {
  _FakeDownload(this.bytes) : super(Dio());

  final int bytes;
  bool called = false;

  @override
  Future<void> download({
    required String url,
    required File target,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    called = true;
    onProgress(0.5);
    _writeSparse(target, bytes);
    onProgress(1);
  }
}

/// Sparse write, so a 158 MB file costs no time or disk in the test.
void _writeSparse(File file, int size) {
  final RandomAccessFile handle = file.openSync(mode: FileMode.write);
  if (size > 0) {
    handle.setPositionSync(size - 1);
    handle.writeByteSync(0);
  }
  handle.closeSync();
}

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('model_test'));
  tearDown(() => directory.deleteSync(recursive: true));

  test('a complete download becomes the final model file', () async {
    final _FakeDownload service = _FakeDownload(
      ModelConstants.vocalsModelSizeInBytes,
    );
    final List<double> progress = <double>[];

    final DataState<void> result =
        await SeparationModelRepositoryImpl(_TempStorage(directory), service)
            .ensureDownloaded(onProgress: progress.add);

    expect(result, isA<DataSuccess<void>>());
    expect(File('${directory.path}/model.onnx').existsSync(), isTrue);
    expect(File('${directory.path}/model.onnx.part').existsSync(), isFalse);
    expect(progress, <double>[0.5, 1]);
  });

  test('a truncated download fails and leaves nothing behind', () async {
    final _FakeDownload service = _FakeDownload(1024);

    final DataState<void> result =
        await SeparationModelRepositoryImpl(_TempStorage(directory), service)
            .ensureDownloaded(onProgress: (_) {});

    expect(result, isA<DataFailed<void>>());
    expect(
      (result as DataFailed<void>).failure,
      AppFailure.modelDownloadFailed,
    );
    expect(directory.listSync(), isEmpty);
  });

  test('an already present model is not downloaded again', () async {
    _writeSparse(
      File('${directory.path}/model.onnx'),
      ModelConstants.vocalsModelSizeInBytes,
    );
    final _FakeDownload service = _FakeDownload(0);

    final DataState<void> result =
        await SeparationModelRepositoryImpl(_TempStorage(directory), service)
            .ensureDownloaded(onProgress: (_) {});

    expect(result, isA<DataSuccess<void>>());
    expect(service.called, isFalse);
  });
}
