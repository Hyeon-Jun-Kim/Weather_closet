import Foundation

@MainActor
final class ClosetRepository: ClosetRepositoryProtocol {
    private let localDataSource: ClosetLocalDataSource

    init(localDataSource: ClosetLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func fetchAll() async throws -> [ClothingEntity] {
        try await localDataSource.fetchAll()
    }

    func fetch(by id: UUID) async throws -> ClothingEntity? {
        try await localDataSource.fetch(by: id)
    }

    func save(_ clothing: ClothingEntity) async throws {
        try await localDataSource.save(clothing)
    }

    func update(_ clothing: ClothingEntity) async throws {
        try await localDataSource.update(clothing)
    }

    func delete(id: UUID) async throws {
        try await localDataSource.delete(id: id)
    }

    func fetchOutfits() async throws -> [OutfitEntity] {
        try await localDataSource.fetchOutfits()
    }

    func saveOutfit(_ outfit: OutfitEntity) async throws {
        try await localDataSource.saveOutfit(outfit)
    }

    func updateOutfit(_ outfit: OutfitEntity) async throws {
        try await localDataSource.updateOutfit(outfit)
    }

    func deleteOutfit(id: UUID) async throws {
        try await localDataSource.deleteOutfit(id: id)
    }
}
