import AVFoundation
import Foundation

enum VideoMuterError: Error {
    case noVideoTrack
    case exportFailed(String)
}

/// Builds a composition that holds only the video track, then exports it with
/// the passthrough preset. Passthrough copies the samples instead of encoding
/// them, so quality is untouched and the export finishes quickly.
enum VideoMuter {

    static func removeSound(
        sourcePath: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let asset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(VideoMuterError.noVideoTrack))
            return
        }

        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            completion(.failure(VideoMuterError.exportFailed("could not add a track")))
            return
        }

        do {
            try track.insertTimeRange(
                CMTimeRange(start: .zero, duration: asset.duration),
                of: videoTrack,
                at: .zero
            )
            // Keeps portrait clips upright in the exported file.
            track.preferredTransform = videoTrack.preferredTransform
        } catch {
            completion(.failure(error))
            return
        }

        export(composition: composition, completion: completion)
    }

    private static func export(
        composition: AVMutableComposition,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let session = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            completion(.failure(VideoMuterError.exportFailed("no export session")))
            return
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("muted_\(Int(Date().timeIntervalSince1970 * 1000)).mp4")

        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true

        session.exportAsynchronously {
            switch session.status {
            case .completed:
                completion(.success(outputURL.path))
            default:
                let reason = session.error?.localizedDescription ?? "export did not finish"
                completion(.failure(VideoMuterError.exportFailed(reason)))
            }
        }
    }
}
