import Vision
import CoreImage
import UIKit

enum BackgroundRemovalError: LocalizedError {
    case invalidImage
    case noForegroundFound
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:      return "이미지를 처리할 수 없습니다."
        case .noForegroundFound: return "전경 객체를 찾지 못했습니다."
        case .processingFailed:  return "배경 제거 처리에 실패했습니다."
        }
    }
}

final class RemoveBgService: @unchecked Sendable {
    static let shared = RemoveBgService()
    private init() {}

    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else { throw BackgroundRemovalError.invalidImage }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let scale = image.scale
        let uiOrientation = image.imageOrientation

        return try await Task.detached(priority: .userInitiated) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            try handler.perform([request])

            guard let observation = request.results?.first else {
                throw BackgroundRemovalError.noForegroundFound
            }

            let maskedBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )

            let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
            let context = CIContext()
            guard let cgResult = context.createCGImage(ciImage, from: ciImage.extent) else {
                throw BackgroundRemovalError.processingFailed
            }

            return UIImage(cgImage: cgResult, scale: scale, orientation: uiOrientation)
        }.value
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:            self = .up
        case .down:          self = .down
        case .left:          self = .left
        case .right:         self = .right
        case .upMirrored:    self = .upMirrored
        case .downMirrored:  self = .downMirrored
        case .leftMirrored:  self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}
