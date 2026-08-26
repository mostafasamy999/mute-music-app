import 'dart:io';

import 'package:dio/dio.dart';

/// Downloads one large file and reports how far it got.
/// Concrete on purpose — a download service gets no interface.
class ModelDownloadService {
  const ModelDownloadService(this._dio);

  final Dio _dio;

  Future<void> download({
    required String url,
    required File target,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) => _dio.download(
    url,
    target.path,
    cancelToken: cancelToken,
    onReceiveProgress: (int received, int total) {
      if (total > 0) onProgress(received / total);
    },
  );
}
