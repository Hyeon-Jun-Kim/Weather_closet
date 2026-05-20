import Foundation

@MainActor
protocol ClosetRepositoryProtocol {
    func fetchAll() async throws -> [ClothingEntity]
    func fetch(by id: UUID) async throws -> ClothingEntity?
    func save(_ clothing: ClothingEntity) async throws
    func update(_ clothing: ClothingEntity) async throws
    func delete(id: UUID) async throws
    func fetchOutfits() async throws -> [OutfitEntity]
    func saveOutfit(_ outfit: OutfitEntity) async throws
    func updateOutfit(_ outfit: OutfitEntity) async throws
    func deleteOutfit(id: UUID) async throws
}
