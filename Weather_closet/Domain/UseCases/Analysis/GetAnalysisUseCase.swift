import Foundation

struct AnalysisResult {
    let frequentCategories: [(ClothingCategory, Int)]
    let colorDistribution: [(String, Int)]
    let categoryDistribution: [(ClothingCategory, Int)]
    let monthlyExpenditure: [(String, Double)]
    let totalPurchaseCount: Int
    let totalSpent: Double
    let averageWearCount: Double
    let leastWornItems: [ClothingEntity]
}

@MainActor
final class GetAnalysisUseCase {
    private let closetRepository: ClosetRepositoryProtocol
    private let calendarRepository: CalendarRepositoryProtocol

    init(closetRepository: ClosetRepositoryProtocol, calendarRepository: CalendarRepositoryProtocol) {
        self.closetRepository = closetRepository
        self.calendarRepository = calendarRepository
    }

    func execute() async throws -> AnalysisResult {
        let clothes = try await closetRepository.fetchAll()
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
        let events = try await calendarRepository.fetchEvents(in: startOfYear...Date())

        let categoryCount = Dictionary(grouping: clothes, by: \.category)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }

        let colorCount = Dictionary(grouping: clothes, by: \.color)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }

        let purchaseEvents = events.compactMap { event -> PurchaseLogEntity? in
            if case .purchase(let log) = event.type { return log }
            return nil
        }
        let monthlySpend = Dictionary(grouping: purchaseEvents) { event -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: events.first(where: {
                if case .purchase(let l) = $0.type { return l.clothingName == event.clothingName }
                return false
            })?.date ?? Date())
        }.mapValues { logs in logs.reduce(0) { $0 + $1.price } }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }

        let leastWorn = clothes.filter { $0.isActive }.sorted { $0.wearCount < $1.wearCount }.prefix(5)

        return AnalysisResult(
            frequentCategories: categoryCount,
            colorDistribution: colorCount,
            categoryDistribution: categoryCount,
            monthlyExpenditure: monthlySpend,
            totalPurchaseCount: purchaseEvents.count,
            totalSpent: purchaseEvents.reduce(0) { $0 + $1.price },
            averageWearCount: clothes.isEmpty ? 0 : Double(clothes.map(\.wearCount).reduce(0, +)) / Double(clothes.count),
            leastWornItems: Array(leastWorn)
        )
    }
}
