import Foundation

@MainActor
final class DeleteClothingUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
