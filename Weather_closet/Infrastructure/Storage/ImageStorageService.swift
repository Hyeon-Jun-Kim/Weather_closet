import UIKit

final class ImageStorageService: @unchecked Sendable {
    static let shared = ImageStorageService()

    private let directory: URL

    private init() {
        directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClothingImages")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ image: UIImage, name: String) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.compressionFailed
        }
        let url = directory.appendingPathComponent("\(name).jpg")
        try data.write(to: url, options: .atomic)
        return url.path
    }

    func load(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    func delete(path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    enum StorageError: Error {
        case compressionFailed
    }
}
