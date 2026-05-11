import Foundation

@MainActor
final class AddClothingUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ clothing: ClothingEntity) async throws {
        try await repository.save(clothing)
    }
}
