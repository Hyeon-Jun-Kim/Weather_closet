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
        let fileName = "\(name).jpg"
        let url = directory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return fileName  // 파일명만 저장 — 절대 경로는 앱 재설치 시 변경됨
    }

    func load(path: String) -> UIImage? {
        let resolvedPath = resolve(path)
        if let image = UIImage(contentsOfFile: resolvedPath) { return image }
        // 레거시 절대 경로로 저장된 경우 파일명만 추출해 재시도
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        return UIImage(contentsOfFile: directory.appendingPathComponent(fileName).path)
    }

    func delete(path: String) {
        try? FileManager.default.removeItem(atPath: resolve(path))
    }

    private func resolve(_ path: String) -> String {
        // 절대 경로면 그대로, 파일명(상대)이면 directory에 붙여 반환
        path.hasPrefix("/") ? path : directory.appendingPathComponent(path).path
    }

    enum StorageError: Error {
        case compressionFailed
    }
}
