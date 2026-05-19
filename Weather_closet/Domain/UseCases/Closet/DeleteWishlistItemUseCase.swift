import Foundation

@MainActor
final class DeleteWishlistItemUseCase {
    private let repository: WishlistRepositoryProtocol
    init(repository: WishlistRepositoryProtocol) { self.repository = repository }
    func execute(id: UUID) async throws { try await repository.delete(id: id) }
}
