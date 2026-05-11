import Foundation

@MainActor
final class GetCalendarEventsUseCase {
    private let repository: CalendarRepositoryProtocol

    init(repository: CalendarRepositoryProtocol) {
        self.repository = repository
    }

    func execute(for date: Date) async throws -> [CalendarEventEntity] {
        try await repository.fetchEvents(for: date)
    }

    func execute(in range: ClosedRange<Date>) async throws -> [CalendarEventEntity] {
        try await repository.fetchEvents(in: range)
    }
}
