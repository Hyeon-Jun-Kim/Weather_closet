import Foundation

@MainActor
final class AddOutfitUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ outfit: OutfitEntity) async throws {
        try await repository.saveOutfit(outfit)
    }
}
