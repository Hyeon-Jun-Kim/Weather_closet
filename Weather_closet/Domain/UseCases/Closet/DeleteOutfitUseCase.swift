import Foundation

@MainActor
final class DeleteOutfitUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.deleteOutfit(id: id)
    }
}
