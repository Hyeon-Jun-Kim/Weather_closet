import Foundation

@MainActor
protocol CalendarRepositoryProtocol {
    func fetchEvents(in range: ClosedRange<Date>) async throws -> [CalendarEventEntity]
    func fetchEvents(for date: Date) async throws -> [CalendarEventEntity]
    func save(_ event: CalendarEventEntity) async throws
    func update(_ event: CalendarEventEntity) async throws
    func delete(id: UUID) async throws
}
