/// The separation model is too big to ship inside the app, so it is downloaded
/// once on first use and kept on the device after that.
abstract final class ModelConstants {
  /// Name of the Dio instance reserved for large file downloads.
  static const String downloadDioName = 'FileDownload';

  static const String vocalsModelUrl =
      'https://github.com/TRvlvr/model_repo/releases/download/'
      'all_public_uvr_models/kuielab_a_vocals.onnx';

  static const String vocalsModelFileName = 'kuielab_a_vocals.onnx';

  /// Exact size on the server. A file of any other size is a broken download.
  static const int vocalsModelSizeInBytes = 29703204;

  /// Suffix used while bytes are still arriving.
  static const String partialSuffix = '.part';

  /// Fixed input the model expects: [batch, 4, freq bins, time frames].
  static const List<int> inputShape = <int>[1, 4, 2048, 512];

  static const String inputName = 'input';
}
