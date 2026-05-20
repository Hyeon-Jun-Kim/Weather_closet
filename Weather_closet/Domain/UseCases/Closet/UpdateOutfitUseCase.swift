import Foundation

@MainActor
final class UpdateOutfitUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ outfit: OutfitEntity) async throws {
        try await repository.updateOutfit(outfit)
    }
}
