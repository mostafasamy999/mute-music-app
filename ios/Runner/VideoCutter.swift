import AVFoundation
import Foundation

enum VideoCutterError: Error {
    case noVideoTrack
    case badRange
    case exportFailed(String)
}

/// The file the cutter wrote, and the range of the source it really covers.
struct CutResult {
    let path: String
    let startMs: Int
    let endMs: Int
}

/// Copies one time range of a video, video and audio, into a new MP4 with the
/// passthrough preset. Nothing is re-encoded, so a cut takes about a second
/// whatever the source length. The whole asset is exported (not a
/// composition), so the orientation and every track come along.
enum VideoCutter {

    static func cut(
        sourcePath: String,
        startMs: Int,
        endMs: Int,
        completion: @escaping (Result<CutResult, Error>) -> Void
    ) {
        let asset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))
        guard !asset.tracks(withMediaType: .video).isEmpty else {
            completion(.failure(VideoCutterError.noVideoTrack))
            return
        }

        let durationMs = Int(CMTimeGetSeconds(asset.duration) * 1000)
        let end = min(endMs, durationMs)
        guard startMs >= 0, startMs < end else {
            completion(.failure(VideoCutterError.badRange))
            return
        }

        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            completion(.failure(VideoCutterError.exportFailed("no export session")))
            return
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("part_\(Int(Date().timeIntervalSince1970 * 1000)).mp4")
        let start = CMTime(value: CMTimeValue(startMs), timescale: 1000)
        let length = CMTime(value: CMTimeValue(end - startMs), timescale: 1000)

        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.timeRange = CMTimeRange(start: start, duration: length)
        session.shouldOptimizeForNetworkUse = true

        session.exportAsynchronously {
            switch session.status {
            case .completed:
                // Passthrough writes an edit list, so playback starts at the
                // asked start. The length it really kept tells us the end.
                let written = AVURLAsset(url: outputURL).duration
                let writtenMs = Int(CMTimeGetSeconds(written) * 1000)
                completion(.success(CutResult(
                    path: outputURL.path,
                    startMs: startMs,
                    endMs: writtenMs > 0 ? startMs + writtenMs : end
                )))
            default:
                try? FileManager.default.removeItem(at: outputURL)
                let reason = session.error?.localizedDescription ?? "export did not finish"
                completion(.failure(VideoCutterError.exportFailed(reason)))
            }
        }
    }

    /// The length of a video in milliseconds, or nil when it can't be read.
    static func durationMs(path: String) -> Int? {
        let seconds = CMTimeGetSeconds(AVURLAsset(url: URL(fileURLWithPath: path)).duration)
        return seconds.isFinite && seconds > 0 ? Int(seconds * 1000) : nil
    }
}
