import Foundation

@MainActor
final class GetOutfitListUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [OutfitEntity] {
        try await repository.fetchOutfits()
    }
}
