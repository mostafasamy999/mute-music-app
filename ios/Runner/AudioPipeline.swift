import AVFoundation
import Foundation

enum AudioPipelineError: Error {
    case noAudioTrack
    case noVideoTrack
    case failed(String)
}

struct PcmInfo {
    let path: String
    let sampleRate: Int
    let channels: Int
}

/// Pulls audio out of a video as raw float samples, and puts new audio back
/// while copying the video track untouched.
enum AudioPipeline {

    static let sampleRate = 44100
    static let channels = 2

    // MARK: - Extract

    static func extractToPcm(sourcePath: String, output: URL) throws -> PcmInfo {
        let asset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))
        guard let track = asset.tracks(withMediaType: .audio).first else {
            throw AudioPipelineError.noAudioTrack
        }
        let reader = try AVAssetReader(asset: asset)
        // AVFoundation resamples to 44.1 kHz stereo float for us.
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        reader.add(trackOutput)
        reader.startReading()

        FileManager.default.createFile(atPath: output.path, contents: nil)
        let handle = try FileHandle(forWritingTo: output)
        defer { try? handle.close() }

        while let buffer = trackOutput.copyNextSampleBuffer() {
            if let data = pcmData(from: buffer) { handle.write(data) }
            CMSampleBufferInvalidate(buffer)
        }
        if reader.status == .failed {
            throw AudioPipelineError.failed(reader.error?.localizedDescription ?? "read failed")
        }
        return PcmInfo(path: output.path, sampleRate: sampleRate, channels: channels)
    }

    private static func pcmData(from buffer: CMSampleBuffer) -> Data? {
        guard let block = CMSampleBufferGetDataBuffer(buffer) else { return nil }
        var length = 0
        var pointer: UnsafeMutablePointer<Int8>?
        guard CMBlockBufferGetDataPointer(
            block, atOffset: 0, lengthAtOffsetOut: nil,
            totalLengthOut: &length, dataPointerOut: &pointer
        ) == kCMBlockBufferNoErr, let raw = pointer else { return nil }
        return Data(bytes: raw, count: length)
    }

    // MARK: - Mux

    static func muxWithNewAudio(
        videoPath: String,
        pcmPath: String,
        outputDir: URL
    ) throws -> String {
        let wav = outputDir.appendingPathComponent("nomusic_\(Int(Date().timeIntervalSince1970 * 1000)).wav")
        try writeWav(from: URL(fileURLWithPath: pcmPath), to: wav)
        defer { try? FileManager.default.removeItem(at: wav) }

        let output = outputDir.appendingPathComponent("nomusic_\(Int(Date().timeIntervalSince1970 * 1000)).mp4")
        try? FileManager.default.removeItem(at: output)
        try writeMovie(videoPath: videoPath, audio: wav, output: output)
        return output.path
    }

    /// Wraps the raw floats so AVFoundation can read them as an asset.
    private static func writeWav(from pcm: URL, to wav: URL) throws {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(sampleRate),
            channels: AVAudioChannelCount(channels),
            interleaved: true
        ) else { throw AudioPipelineError.failed("bad audio format") }

        let data = try Data(contentsOf: pcm)
        let frames = data.count / (4 * channels)
        guard frames > 0 else { throw AudioPipelineError.failed("empty audio") }

        let file = try AVAudioFile(
            forWriting: wav, settings: format.settings,
            commonFormat: .pcmFormatFloat32, interleaved: true
        )
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)
        ) else { throw AudioPipelineError.failed("buffer alloc failed") }
        buffer.frameLength = AVAudioFrameCount(frames)
        data.withUnsafeBytes { raw in
            if let src = raw.baseAddress, let dst = buffer.floatChannelData?[0] {
                memcpy(dst, src, frames * 4 * channels)
            }
        }
        try file.write(from: buffer)
    }

    private static func writeMovie(videoPath: String, audio: URL, output: URL) throws {
        let videoAsset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            throw AudioPipelineError.noVideoTrack
        }
        let audioAsset = AVURLAsset(url: audio)
        guard let audioTrack = audioAsset.tracks(withMediaType: .audio).first else {
            throw AudioPipelineError.noAudioTrack
        }

        let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)

        // nil output settings means "copy the samples", so the picture is never
        // re-encoded. MP4 cannot hold raw audio, so that side becomes AAC.
        // A pass-through input into .mp4 needs the source format, or addInput
        // throws and the app aborts (spec 006 S15).
        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: nil,
            sourceFormatHint: (videoTrack.formatDescriptions.first as! CMFormatDescription)
        )
        videoInput.expectsMediaDataInRealTime = false
        videoInput.transform = videoTrack.preferredTransform
        writer.add(videoInput)

        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderBitRateKey: 192_000,
        ])
        audioInput.expectsMediaDataInRealTime = false
        writer.add(audioInput)

        let videoReader = try AVAssetReader(asset: videoAsset)
        let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
        videoReader.add(videoOutput)

        let audioReader = try AVAssetReader(asset: audioAsset)
        let audioOutput = AVAssetReaderTrackOutput(
            track: audioTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM]
        )
        audioReader.add(audioOutput)

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        videoReader.startReading()
        audioReader.startReading()

        let group = DispatchGroup()
        pump(videoInput, videoOutput, "video", group)
        pump(audioInput, audioOutput, "audio", group)
        group.wait()

        let finish = DispatchGroup()
        finish.enter()
        writer.finishWriting { finish.leave() }
        finish.wait()

        if writer.status != .completed {
            throw AudioPipelineError.failed(
                writer.error?.localizedDescription ?? "write did not finish"
            )
        }
    }

    private static func pump(
        _ input: AVAssetWriterInput,
        _ output: AVAssetReaderTrackOutput,
        _ label: String,
        _ group: DispatchGroup
    ) {
        group.enter()
        input.requestMediaDataWhenReady(on: DispatchQueue(label: label)) {
            while input.isReadyForMoreMediaData {
                guard let buffer = output.copyNextSampleBuffer() else {
                    input.markAsFinished()
                    group.leave()
                    return
                }
                // Not invalidated after append: the writer may still read it
                // ("Failed to load sample data", spec 006 S15).
                input.append(buffer)
            }
        }
    }
}
