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
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
