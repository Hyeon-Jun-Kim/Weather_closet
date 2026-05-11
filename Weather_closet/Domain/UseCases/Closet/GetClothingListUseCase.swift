import Foundation

@MainActor
final class GetClothingListUseCase {
    private let repository: ClosetRepositoryProtocol

    init(repository: ClosetRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [ClothingEntity] {
        try await repository.fetchAll()
    }

    func execute(category: ClothingCategory) async throws -> [ClothingEntity] {
        let all = try await repository.fetchAll()
        return all.filter { $0.category == category }
    }
}
