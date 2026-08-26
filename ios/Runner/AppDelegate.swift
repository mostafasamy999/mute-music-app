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
            guard call.method == "removeSound" else {
                result(FlutterMethodNotImplemented)
                return
            }
            Self.handleRemoveSound(call: call, result: result)
        }
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

    private static func flutterError(for error: Error) -> FlutterError {
        if case VideoMuterError.noVideoTrack = error {
            return FlutterError(code: "no_video_track", message: "no video track", details: nil)
        }
        return FlutterError(code: "mute_failed", message: error.localizedDescription, details: nil)
    }
}
