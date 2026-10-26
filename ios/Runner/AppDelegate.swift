import Flutter
import UIKit
import os

@main
@objc class AppDelegate: FlutterAppDelegate {

    private static let channelName = "com.mostafasamy.mutemusic/video"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        setUpVideoChannel()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setUpVideoChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        let channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "removeSound":
                Self.handleRemoveSound(call: call, result: result)
            case "memoryReport":
                result(Self.memoryReport())
            case "extractAudio":
                Self.handleExtractAudio(call: call, result: result)
            case "muxAudio":
                Self.handleMuxAudio(call: call, result: result)
            case "cutVideo":
                Self.handleCutVideo(call: call, result: result)
            case "cutAudio":
                Self.handleCutAudio(call: call, result: result)
            case "exportAudio":
                Self.handleExportAudio(call: call, result: result)
            case "saveAudio":
                Self.handleSaveAudio(call: call, result: result)
            case "encodeVoices":
                Self.handleEncodeVoices(call: call, result: result)
            case "recognizeText":
                Self.handleRecognizeText(call: call, result: result)
            case "ocrSupportsArabic":
                result(TextRecognizer.supportsArabic())
            case "videoDuration":
                Self.handleVideoDuration(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// phys_footprint is exactly what jetsam looks at before killing an app,
    /// so it is the honest number for "will this survive on a real iPhone".
    private static func memoryReport() -> [String: Any] {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let status: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        let footprint = status == KERN_SUCCESS
            ? Double(info.phys_footprint) / 1048576.0
            : -1
        return [
            "footprintMb": footprint,
            "nativeHeapMb": -1,
            "deviceTotalMb": Double(ProcessInfo.processInfo.physicalMemory) / 1048576.0,
            "deviceAvailableMb": Double(os_proc_available_memory()) / 1048576.0,
            "lowMemoryThresholdMb": -1,
            "heapLimitMb": -1,
            "lowMemory": false,
        ]
    }

    private static func handleRemoveSound(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let arguments = call.arguments as? [String: Any],
              let sourcePath = arguments["sourcePath"] as? String,
              !sourcePath.isEmpty else {
            result(FlutterError(code: "bad_argument", message: "sourcePath is missing", details: nil))
            return
        }
        VideoMuter.removeSound(sourcePath: sourcePath) { outcome in
            DispatchQueue.main.async {
                switch outcome {
                case .success(let path):
                    result(path)
                case .failure(let error):
                    result(flutterError(for: error))
                }
            }
        }
    }

    private static func handleExtractAudio(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let sourcePath = args["sourcePath"] as? String, !sourcePath.isEmpty else {
            result(FlutterError(code: "bad_argument", message: "sourcePath is missing", details: nil))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let target = FileManager.default.temporaryDirectory
                    .appendingPathComponent("audio_\(Int(Date().timeIntervalSince1970 * 1000)).pcm")
                let info = try AudioPipeline.extractToPcm(sourcePath: sourcePath, output: target)
                DispatchQueue.main.async {
                    result([
                        "path": info.path,
                        "sampleRate": info.sampleRate,
                        "channels": info.channels,
                    ])
                }
            } catch {
                DispatchQueue.main.async { result(audioError(error, fallback: "extract_failed")) }
            }
        }
    }

    private static func handleMuxAudio(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["videoPath"] as? String,
              let pcmPath = args["pcmPath"] as? String else {
            result(FlutterError(code: "bad_argument", message: "paths are missing", details: nil))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let path = try AudioPipeline.muxWithNewAudio(
                    videoPath: videoPath,
                    pcmPath: pcmPath,
                    outputDir: FileManager.default.temporaryDirectory
                )
                DispatchQueue.main.async { result(path) }
            } catch {
                DispatchQueue.main.async { result(audioError(error, fallback: "mux_failed")) }
            }
        }
    }

    private static func handleCutVideo(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let sourcePath = args["sourcePath"] as? String, !sourcePath.isEmpty,
              let startMs = (args["startMs"] as? NSNumber)?.intValue,
              let endMs = (args["endMs"] as? NSNumber)?.intValue else {
            result(FlutterError(code: "bad_argument", message: "sourcePath, startMs or endMs is missing", details: nil))
            return
        }
        VideoCutter.cut(sourcePath: sourcePath, startMs: startMs, endMs: endMs) { outcome in
            DispatchQueue.main.async {
                switch outcome {
                case .success(let cut):
                    result(["path": cut.path, "startMs": cut.startMs, "endMs": cut.endMs])
                case .failure(let error):
                    result(cutError(error))
                }
            }
        }
    }

    /// Spec 006 F3: cuts a sound file into a new .m4a (AudioExporter).
    private static func handleCutAudio(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let sourcePath = args["sourcePath"] as? String, !sourcePath.isEmpty,
              let startMs = (args["startMs"] as? NSNumber)?.intValue,
              let endMs = (args["endMs"] as? NSNumber)?.intValue else {
            result(FlutterError(code: "bad_argument", message: "sourcePath, startMs or endMs is missing", details: nil))
            return
        }
        AudioExporter.export(
            sourcePath: sourcePath,
            prefix: "part",
            startMs: startMs,
            endMs: endMs
        ) { outcome in
            DispatchQueue.main.async {
                switch outcome {
                case .success(let cut):
                    result(["path": cut.path, "startMs": cut.startMs, "endMs": cut.endMs])
                case .failure(let error):
                    result(exportError(error, fallback: "cut_failed"))
                }
            }
        }
    }

    /// Spec 006 F7: Convert to audio. The whole audio track into an .m4a.
    private static func handleExportAudio(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let sourcePath = args["sourcePath"] as? String, !sourcePath.isEmpty else {
            result(FlutterError(code: "bad_argument", message: "sourcePath is missing", details: nil))
            return
        }
        AudioExporter.export(sourcePath: sourcePath, prefix: "export") { outcome in
            DispatchQueue.main.async {
                switch outcome {
                case .success(let export):
                    result(export.path)
                case .failure(let error):
                    result(exportError(error, fallback: "convert_failed"))
                }
            }
        }
    }

    /// Spec 006 F10 (Q5): apps can't add to the Music library on iOS, so the
    /// file goes into Documents/Mute Video, which the Files app shows under
    /// On My iPhone › Mute Video (UIFileSharingEnabled in Info.plist).
    private static func handleSaveAudio(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let sourcePath = args["sourcePath"] as? String, !sourcePath.isEmpty,
              let name = args["name"] as? String, !name.isEmpty else {
            result(FlutterError(code: "bad_argument", message: "sourcePath or name is missing", details: nil))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let files = FileManager.default
            do {
                let documents = try files.url(
                    for: .documentDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true
                )
                let folder = documents.appendingPathComponent("Mute Video", isDirectory: true)
                try files.createDirectory(at: folder, withIntermediateDirectories: true)
                let target = folder.appendingPathComponent(name)
                if files.fileExists(atPath: target.path) {
                    try files.removeItem(at: target)
                }
                try files.copyItem(at: URL(fileURLWithPath: sourcePath), to: target)
                DispatchQueue.main.async { result(nil) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    /// Spec 006 F8: offline text from an image (Vision, Arabic + English).
    private static func handleRecognizeText(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String, !imagePath.isEmpty else {
            result(FlutterError(code: "bad_argument", message: "imagePath is missing", details: nil))
            return
        }
        TextRecognizer.recognize(imagePath: imagePath) { outcome in
            DispatchQueue.main.async {
                switch outcome {
                case .success(let text):
                    result(text)
                case .failure(TextRecognizerError.unreadableImage):
                    result(FlutterError(code: "unreadable_image", message: "image can't be read", details: nil))
                case .failure(let error):
                    result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    /// Spec 006 F6: the separated voices of a sound file into an .m4a.
    private static func handleEncodeVoices(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let pcmPath = args["pcmPath"] as? String, !pcmPath.isEmpty,
              let sampleRate = (args["sampleRate"] as? NSNumber)?.doubleValue,
              let channels = (args["channels"] as? NSNumber)?.intValue else {
            result(FlutterError(code: "bad_argument", message: "pcmPath, sampleRate or channels is missing", details: nil))
            return
        }
        PcmEncoder.encode(pcmPath: pcmPath, sampleRate: sampleRate, channels: channels) { outcome in
            DispatchQueue.main.async {
                switch outcome {
                case .success(let path):
                    result(path)
                case .failure(let error):
                    result(FlutterError(code: "encode_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private static func exportError(_ error: Error, fallback: String) -> FlutterError {
        switch error {
        case AudioExporterError.noAudioTrack:
            return FlutterError(code: "no_audio_track", message: "no audio track", details: nil)
        case AudioExporterError.badRange:
            return FlutterError(code: "bad_range", message: "range outside the file", details: nil)
        default:
            return FlutterError(code: fallback, message: error.localizedDescription, details: nil)
        }
    }

    private static func handleVideoDuration(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let sourcePath = args["sourcePath"] as? String, !sourcePath.isEmpty else {
            result(FlutterError(code: "bad_argument", message: "sourcePath is missing", details: nil))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let durationMs = VideoCutter.durationMs(path: sourcePath)
            DispatchQueue.main.async { result(durationMs) }
        }
    }

    private static func cutError(_ error: Error) -> FlutterError {
        switch error {
        case VideoCutterError.noVideoTrack:
            return FlutterError(code: "no_video_track", message: "no video track", details: nil)
        case VideoCutterError.badRange:
            return FlutterError(code: "bad_range", message: "range outside the video", details: nil)
        default:
            return FlutterError(code: "cut_failed", message: error.localizedDescription, details: nil)
        }
    }

    private static func audioError(_ error: Error, fallback: String) -> FlutterError {
        if case AudioPipelineError.noAudioTrack = error {
            return FlutterError(code: "no_audio_track", message: "no audio track", details: nil)
        }
        if case AudioPipelineError.noVideoTrack = error {
            return FlutterError(code: "no_video_track", message: "no video track", details: nil)
        }
        // localizedDescription drops the reason ("…AudioPipelineError error 0").
        if case AudioPipelineError.failed(let reason) = error {
            return FlutterError(code: fallback, message: reason, details: nil)
        }
        return FlutterError(code: fallback, message: error.localizedDescription, details: nil)
    }

    private static func flutterError(for error: Error) -> FlutterError {
        if case VideoMuterError.noVideoTrack = error {
            return FlutterError(code: "no_video_track", message: "no video track", details: nil)
        }
        return FlutterError(code: "mute_failed", message: error.localizedDescription, details: nil)
    }
}
