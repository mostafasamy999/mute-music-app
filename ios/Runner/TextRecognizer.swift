import Foundation
import UIKit
import Vision

enum TextRecognizerError: Error {
    case unreadableImage
    case failed(String)
}

/// Spec 006 F8: text from an image, offline, Arabic and English, with Apple
/// Vision. Android uses Tesseract; Vision reads Arabic on the iOS versions
/// that support it and falls back to English only on older ones.
enum TextRecognizer {

    static func recognize(
        imagePath: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let image = UIImage(contentsOfFile: imagePath), let cgImage = image.cgImage else {
            completion(.failure(TextRecognizerError.unreadableImage))
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(TextRecognizerError.failed(error.localizedDescription)))
                return
            }
            let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
            completion(.success(lines.joined(separator: "\n")))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages(for: request)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: orientation(of: image),
                    options: [:]
                )
                try handler.perform([request])
            } catch {
                completion(.failure(TextRecognizerError.failed(error.localizedDescription)))
            }
        }
    }

    /// Arabic first when this iOS can read it, then English.
    private static func languages(for request: VNRecognizeTextRequest) -> [String] {
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        let wanted = ["ar-SA", "en-US"].filter { supported.contains($0) }
        return wanted.isEmpty ? ["en-US"] : wanted
    }

    private static func orientation(of image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    /// For the integration test: whether this iOS reads Arabic.
    static func supportsArabic() -> Bool {
        let supported = (try? VNRecognizeTextRequest().supportedRecognitionLanguages()) ?? []
        return supported.contains("ar-SA")
    }
}
