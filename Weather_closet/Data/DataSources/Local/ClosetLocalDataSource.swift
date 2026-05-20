import Foundation
import SwiftData

@MainActor
final class ClosetLocalDataSource {
    private let persistence: PersistenceStack

    init(persistence: PersistenceStack) {
        self.persistence = persistence
    }

    func fetchAll() async throws -> [ClothingEntity] {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<ClothingModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let models = try context.fetch(descriptor)
        return models.map { $0.toEntity() }
    }

    func fetch(by id: UUID) async throws -> ClothingEntity? {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<ClothingModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toEntity()
    }

    func save(_ clothing: ClothingEntity) async throws {
        let context = persistence.modelContext
        let model = ClothingModel(entity: clothing)
        context.insert(model)
        try context.save()
    }

    func update(_ clothing: ClothingEntity) async throws {
        let context = persistence.modelContext
        let clothingID = clothing.id
        let descriptor = FetchDescriptor<ClothingModel>(
            predicate: #Predicate { $0.id == clothingID }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        model.update(from: clothing)
        try context.save()
    }

    func delete(id: UUID) async throws {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<ClothingModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let model = try context.fetch(descriptor).first {
            context.delete(model)
            try context.save()
        }
    }

    func fetchOutfits() async throws -> [OutfitEntity] {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<OutfitModel>()
        return try context.fetch(descriptor).map { $0.toEntity() }
    }

    func saveOutfit(_ outfit: OutfitEntity) async throws {
        let context = persistence.modelContext
        let model = OutfitModel(entity: outfit)
        context.insert(model)
        try context.save()
    }

    func updateOutfit(_ outfit: OutfitEntity) async throws {
        let context = persistence.modelContext
        let outfitID = outfit.id
        let descriptor = FetchDescriptor<OutfitModel>(
            predicate: #Predicate { $0.id == outfitID }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        model.update(from: outfit)
        try context.save()
    }

    func deleteOutfit(id: UUID) async throws {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<OutfitModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let model = try context.fetch(descriptor).first {
            context.delete(model)
            try context.save()
        }
    }
}
