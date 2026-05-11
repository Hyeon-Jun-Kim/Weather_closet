import Foundation
import SwiftData

@MainActor
final class UserLocalDataSource {
    private let persistence: PersistenceStack

    init(persistence: PersistenceStack) {
        self.persistence = persistence
    }

    func fetchUser() async throws -> UserEntity? {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<UserModel>()
        return try context.fetch(descriptor).first?.toEntity()
    }

    func saveUser(_ user: UserEntity) async throws {
        let context = persistence.modelContext
        let existing = try context.fetch(FetchDescriptor<UserModel>()).first
        if let model = existing {
            model.update(from: user)
        } else {
            context.insert(UserModel(entity: user))
        }
        try context.save()
    }

    func addBodyMeasurement(_ measurement: BodyMeasurement) async throws {
        let context = persistence.modelContext
        let model = BodyMeasurementModel(entity: measurement)
        context.insert(model)
        try context.save()
    }

    func fetchBodyMeasurements() async throws -> [BodyMeasurement] {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<BodyMeasurementModel>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toEntity() }
    }
}
