import Foundation

@MainActor
final class RecordOutfitUseCase {
    private let repository: CalendarRepositoryProtocol

    init(repository: CalendarRepositoryProtocol) {
        self.repository = repository
    }

    func execute(date: Date, outfitLog: OutfitLogEntity) async throws {
        let event = CalendarEventEntity(
            id: UUID(),
            date: date,
            type: .outfit(outfitLog)
        )
        try await repository.save(event)
    }

    func recordPurchase(date: Date, log: PurchaseLogEntity) async throws {
        let event = CalendarEventEntity(
            id: UUID(),
            date: date,
            type: .purchase(log)
        )
        try await repository.save(event)
    }

    func recordSale(date: Date, log: SaleLogEntity) async throws {
        let event = CalendarEventEntity(
            id: UUID(),
            date: date,
            type: .sale(log)
        )
        try await repository.save(event)
    }

    func update(_ event: CalendarEventEntity) async throws {
        try await repository.update(event)
    }

    func delete(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
