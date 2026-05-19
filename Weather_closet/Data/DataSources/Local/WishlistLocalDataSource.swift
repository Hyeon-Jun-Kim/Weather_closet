import Foundation
import SwiftData

@MainActor
final class WishlistLocalDataSource {
    private let persistence: PersistenceStack

    init(persistence: PersistenceStack) { self.persistence = persistence }

    func fetchAll() async throws -> [WishlistItemEntity] {
        let descriptor = FetchDescriptor<WishlistItemModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try persistence.modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func save(_ item: WishlistItemEntity) async throws {
        persistence.modelContext.insert(WishlistItemModel(entity: item))
        try persistence.modelContext.save()
    }

    func update(_ item: WishlistItemEntity) async throws {
        let id = item.id
        let descriptor = FetchDescriptor<WishlistItemModel>(predicate: #Predicate { $0.id == id })
        guard let model = try persistence.modelContext.fetch(descriptor).first else { return }
        model.update(from: item)
        try persistence.modelContext.save()
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<WishlistItemModel>(predicate: #Predicate { $0.id == id })
        if let model = try persistence.modelContext.fetch(descriptor).first {
            persistence.modelContext.delete(model)
            try persistence.modelContext.save()
        }
    }

    func updateOrder(_ items: [WishlistItemEntity]) async throws {
        for item in items {
            let id = item.id
            let descriptor = FetchDescriptor<WishlistItemModel>(predicate: #Predicate { $0.id == id })
            if let model = try persistence.modelContext.fetch(descriptor).first {
                model.sortOrder = item.sortOrder
            }
        }
        try persistence.modelContext.save()
    }
}
