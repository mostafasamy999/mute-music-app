import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
// video_asset.dart re-exports media_asset.dart, which this test also checks.
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

/// Spec 006 S4: one asset type for image, sound and video, with no change for
/// the code that still says VideoAsset.
void main() {
  test('a VideoAsset is a MediaAsset of kind video', () {
    const VideoAsset video = VideoAsset(path: '/tmp/a.mp4');

    expect(video, isA<MediaAsset>());
    expect(video.kind, MediaKind.video);
    expect(video.isVideo, isTrue);
    expect(video, const MediaAsset(path: '/tmp/a.mp4', kind: MediaKind.video));
  });

  test('each kind answers only its own check', () {
    const MediaAsset image = MediaAsset(path: '/i.jpg', kind: MediaKind.image);
    const MediaAsset audio = MediaAsset(path: '/s.m4a', kind: MediaKind.audio);

    expect((image.isImage, image.isAudio, image.isVideo), (true, false, false));
    expect((audio.isImage, audio.isAudio, audio.isVideo), (false, true, false));
  });

  test('the kind is part of equality', () {
    const MediaAsset asVideo = MediaAsset(path: '/x');
    const MediaAsset asAudio = MediaAsset(path: '/x', kind: MediaKind.audio);

    expect(asVideo == asAudio, isFalse);
    expect(asVideo.hashCode == asAudio.hashCode, isFalse);
  });

  test('every field still takes part in equality', () {
    final ClipRange range = ClipRange(
      start: Duration.zero,
      end: const Duration(seconds: 3),
    );
    final MediaAsset part = MediaAsset(
      path: '/p.mp4',
      sizeInBytes: 10,
      duration: const Duration(seconds: 3),
      range: range,
    );

    expect(
      part,
      MediaAsset(
        path: '/p.mp4',
        sizeInBytes: 10,
        duration: const Duration(seconds: 3),
        range: range,
      ),
    );
    expect(part == const MediaAsset(path: '/p.mp4', sizeInBytes: 10), isFalse);
  });
}
