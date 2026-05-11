import Foundation

@MainActor
final class CalendarRepository: CalendarRepositoryProtocol {
    private let localDataSource: CalendarLocalDataSource

    init(localDataSource: CalendarLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func fetchEvents(in range: ClosedRange<Date>) async throws -> [CalendarEventEntity] {
        try await localDataSource.fetchEvents(in: range)
    }

    func fetchEvents(for date: Date) async throws -> [CalendarEventEntity] {
        try await localDataSource.fetchEvents(for: date)
    }

    func save(_ event: CalendarEventEntity) async throws {
        try await localDataSource.save(event)
    }

    func update(_ event: CalendarEventEntity) async throws {
        try await localDataSource.update(event)
    }

    func delete(id: UUID) async throws {
        try await localDataSource.delete(id: id)
    }
}
