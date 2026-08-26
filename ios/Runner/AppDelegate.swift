import Flutter
import UIKit

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
            "deviceAvailableMb": -1,
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

    private static func audioError(_ error: Error, fallback: String) -> FlutterError {
        if case AudioPipelineError.noAudioTrack = error {
            return FlutterError(code: "no_audio_track", message: "no audio track", details: nil)
        }
        if case AudioPipelineError.noVideoTrack = error {
            return FlutterError(code: "no_video_track", message: "no video track", details: nil)
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
