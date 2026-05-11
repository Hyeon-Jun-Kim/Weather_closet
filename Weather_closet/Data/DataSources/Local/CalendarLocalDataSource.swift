import Foundation
import SwiftData

@MainActor
final class CalendarLocalDataSource {
    private let persistence: PersistenceStack

    init(persistence: PersistenceStack) {
        self.persistence = persistence
    }

    func fetchEvents(in range: ClosedRange<Date>) async throws -> [CalendarEventEntity] {
        let context = persistence.modelContext
        let start = range.lowerBound
        let end = range.upperBound
        let descriptor = FetchDescriptor<CalendarEventModel>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor).map { $0.toEntity() }
    }

    func fetchEvents(for date: Date) async throws -> [CalendarEventEntity] {
        let context = persistence.modelContext
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let descriptor = FetchDescriptor<CalendarEventModel>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor).map { $0.toEntity() }
    }

    func save(_ event: CalendarEventEntity) async throws {
        let context = persistence.modelContext
        let model = CalendarEventModel(entity: event)
        context.insert(model)
        try context.save()
    }

    func update(_ event: CalendarEventEntity) async throws {
        let context = persistence.modelContext
        let eventID = event.id
        let descriptor = FetchDescriptor<CalendarEventModel>(
            predicate: #Predicate { $0.id == eventID }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        model.update(from: event)
        try context.save()
    }

    func delete(id: UUID) async throws {
        let context = persistence.modelContext
        let descriptor = FetchDescriptor<CalendarEventModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let model = try context.fetch(descriptor).first {
            context.delete(model)
            try context.save()
        }
    }
}
