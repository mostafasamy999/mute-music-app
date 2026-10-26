import AVFoundation
import Foundation

enum AudioExporterError: Error {
    case noAudioTrack
    case badRange
    case exportFailed(String)
}

/// Writes the audio track of a sound or video file, or one time range of it,
/// into a new .m4a (spec 006: cut a sound, Convert to audio). The AppleM4A
/// preset writes AAC from any source codec and leaves any video behind.
///
/// New code next to AudioPipeline and VideoMuter; it does not change them.
enum AudioExporter {

    /// Writes `<prefix>_<time>.m4a` in the temp folder. With [startMs] and
    /// [endMs] only that range is written.
    static func export(
        sourcePath: String,
        prefix: String,
        startMs: Int? = nil,
        endMs: Int? = nil,
        completion: @escaping (Result<CutResult, Error>) -> Void
    ) {
        let asset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))
        guard !asset.tracks(withMediaType: .audio).isEmpty else {
            completion(.failure(AudioExporterError.noAudioTrack))
            return
        }

        let durationMs = Int(CMTimeGetSeconds(asset.duration) * 1000)
        let start = startMs ?? 0
        let end = min(endMs ?? durationMs, durationMs)
        guard start >= 0, start < end else {
            completion(.failure(AudioExporterError.badRange))
            return
        }

        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            completion(.failure(AudioExporterError.exportFailed("no export session")))
            return
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(Int(Date().timeIntervalSince1970 * 1000)).m4a")
        session.outputURL = outputURL
        session.outputFileType = .m4a
        if startMs != nil || endMs != nil {
            session.timeRange = CMTimeRange(
                start: CMTime(value: CMTimeValue(start), timescale: 1000),
                duration: CMTime(value: CMTimeValue(end - start), timescale: 1000)
            )
        }

        session.exportAsynchronously {
            switch session.status {
            case .completed:
                let written = AVURLAsset(url: outputURL).duration
                let writtenMs = Int(CMTimeGetSeconds(written) * 1000)
                completion(.success(CutResult(
                    path: outputURL.path,
                    startMs: start,
                    endMs: writtenMs > 0 ? start + writtenMs : end
                )))
            default:
                try? FileManager.default.removeItem(at: outputURL)
                let reason = session.error?.localizedDescription ?? "export did not finish"
                completion(.failure(AudioExporterError.exportFailed(reason)))
            }
        }
    }
}
