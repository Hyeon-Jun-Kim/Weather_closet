import Foundation

@MainActor
protocol WishlistRepositoryProtocol {
    func fetchAll() async throws -> [WishlistItemEntity]
    func save(_ item: WishlistItemEntity) async throws
    func update(_ item: WishlistItemEntity) async throws
    func delete(id: UUID) async throws
    func updateOrder(_ items: [WishlistItemEntity]) async throws
}
