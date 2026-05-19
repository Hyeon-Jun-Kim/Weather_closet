import Foundation

@MainActor
final class GetWishlistUseCase {
    private let repository: WishlistRepositoryProtocol
    init(repository: WishlistRepositoryProtocol) { self.repository = repository }
    func execute() async throws -> [WishlistItemEntity] { try await repository.fetchAll() }
}
