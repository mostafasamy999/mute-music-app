import AVFoundation
import Foundation

enum PcmEncoderError: Error {
    case missingInput
    case failed(String)
}

/// Spec 006 F6: Remove music only on a sound file. Encodes the separated
/// voices (interleaved float32 PCM, as the separation worker writes it) into
/// a new .m4a, where AudioPipeline would mux them into a video instead.
///
/// New code next to AudioPipeline; it does not change it. The PCM is read in
/// chunks, so a long file is never held in memory twice.
enum PcmEncoder {

    private static let chunkFrames: AVAudioFrameCount = 16 * 1024

    static func encode(
        pcmPath: String,
        sampleRate: Double,
        channels: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("nomusic_\(Int(Date().timeIntervalSince1970 * 1000)).m4a")
            do {
                try write(pcmPath: pcmPath, sampleRate: sampleRate, channels: channels, to: outputURL)
                completion(.success(outputURL.path))
            } catch {
                try? FileManager.default.removeItem(at: outputURL)
                completion(.failure(error))
            }
        }
    }

    private static func write(pcmPath: String, sampleRate: Double, channels: Int, to url: URL) throws {
        guard let input = FileHandle(forReadingAtPath: pcmPath) else {
            throw PcmEncoderError.missingInput
        }
        defer { try? input.close() }

        let channelCount = AVAudioChannelCount(channels)
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        ) else {
            throw PcmEncoderError.failed("no PCM format")
        }
        let file = try AVAudioFile(
            forWriting: url,
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
                AVEncoderBitRateKey: 192_000,
            ],
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        let bytesPerFrame = 4 * channels
        while true {
            let data = input.readData(ofLength: Int(chunkFrames) * bytesPerFrame)
            let frames = data.count / bytesPerFrame
            if frames == 0 { break }
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
                  let planes = buffer.floatChannelData else {
                throw PcmEncoderError.failed("no PCM buffer")
            }
            buffer.frameLength = AVAudioFrameCount(frames)
            // Interleaved little-endian float32 → one plane per channel.
            data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                for frame in 0..<frames {
                    for channel in 0..<channels {
                        let offset = (frame * channels + channel) * 4
                        let bits = raw.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
                        planes[channel][frame] = Float(bitPattern: UInt32(littleEndian: bits))
                    }
                }
            }
            try file.write(from: buffer)
        }
    }
}
