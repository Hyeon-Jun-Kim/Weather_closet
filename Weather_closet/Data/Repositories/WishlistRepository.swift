import Foundation

@MainActor
final class WishlistRepository: WishlistRepositoryProtocol {
    private let localDataSource: WishlistLocalDataSource

    init(localDataSource: WishlistLocalDataSource) { self.localDataSource = localDataSource }

    func fetchAll() async throws -> [WishlistItemEntity] { try await localDataSource.fetchAll() }
    func save(_ item: WishlistItemEntity) async throws { try await localDataSource.save(item) }
    func update(_ item: WishlistItemEntity) async throws { try await localDataSource.update(item) }
    func delete(id: UUID) async throws { try await localDataSource.delete(id: id) }
    func updateOrder(_ items: [WishlistItemEntity]) async throws { try await localDataSource.updateOrder(items) }
}
