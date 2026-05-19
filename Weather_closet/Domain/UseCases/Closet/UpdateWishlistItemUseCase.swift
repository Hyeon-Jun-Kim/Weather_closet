import Foundation

@MainActor
final class UpdateWishlistItemUseCase {
    private let repository: WishlistRepositoryProtocol
    init(repository: WishlistRepositoryProtocol) { self.repository = repository }
    func execute(_ item: WishlistItemEntity) async throws { try await repository.update(item) }
    func executeOrder(_ items: [WishlistItemEntity]) async throws { try await repository.updateOrder(items) }
}
