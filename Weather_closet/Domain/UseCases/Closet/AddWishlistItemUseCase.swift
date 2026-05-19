import Foundation

@MainActor
final class AddWishlistItemUseCase {
    private let repository: WishlistRepositoryProtocol
    init(repository: WishlistRepositoryProtocol) { self.repository = repository }
    func execute(_ item: WishlistItemEntity) async throws { try await repository.save(item) }
}
