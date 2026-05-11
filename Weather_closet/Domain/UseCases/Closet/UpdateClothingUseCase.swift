import Foundation

@MainActor
final class UpdateClothingUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ clothing: ClothingEntity) async throws {
        try await repository.update(clothing)
    }
}
