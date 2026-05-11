import Foundation
import SwiftData

@MainActor
final class PersistenceStack {
    static let shared = PersistenceStack()

    let modelContainer: ModelContainer
    var modelContext: ModelContext { modelContainer.mainContext }

    init() {
        let schema = Schema([
            ClothingModel.self,
            OutfitModel.self,
            CalendarEventModel.self,
            UserModel.self,
            BodyMeasurementModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            // 스키마 변경으로 기존 스토어와 충돌 시 삭제 후 재생성
            PersistenceStack.deleteStoreFiles()
            do {
                modelContainer = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    private static func deleteStoreFiles() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: appSupport, includingPropertiesForKeys: nil
        )) ?? []
        for file in files where file.pathExtension == "store"
                                  || file.lastPathComponent.hasSuffix(".store-shm")
                                  || file.lastPathComponent.hasSuffix(".store-wal") {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
