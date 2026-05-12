import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var eventsForSelectedDate: [CalendarEventEntity] = []
    @Published var clothingList: [ClothingEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let recordOutfitUseCase: RecordOutfitUseCase
    private let getCalendarEventsUseCase: GetCalendarEventsUseCase
    private let getClothingListUseCase: GetClothingListUseCase

    init(
        recordOutfitUseCase: RecordOutfitUseCase,
        getCalendarEventsUseCase: GetCalendarEventsUseCase,
        getClothingListUseCase: GetClothingListUseCase
    ) {
        self.recordOutfitUseCase = recordOutfitUseCase
        self.getCalendarEventsUseCase = getCalendarEventsUseCase
        self.getClothingListUseCase = getClothingListUseCase
    }

    func loadEvents(for date: Date) async {
        do {
            eventsForSelectedDate = try await getCalendarEventsUseCase.execute(for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadClothingList() async {
        do {
            clothingList = try await getClothingListUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recordOutfit(clothingIDs: [UUID], note: String) async {
        do {
            let log = OutfitLogEntity(outfitID: nil, clothingIDs: clothingIDs, weather: nil, note: note)
            try await recordOutfitUseCase.execute(date: selectedDate, outfitLog: log)
            await loadEvents(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recordPurchase(clothingName: String, price: Double, place: String, note: String) async {
        do {
            let log = PurchaseLogEntity(clothingID: nil, clothingName: clothingName, price: price, place: place, note: note)
            try await recordOutfitUseCase.recordPurchase(date: selectedDate, log: log)
            await loadEvents(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEvent(id: UUID) async {
        do {
            try await recordOutfitUseCase.delete(id: id)
            await loadEvents(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateEvent(_ event: CalendarEventEntity) async {
        do {
            try await recordOutfitUseCase.update(event)
            await loadEvents(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recordSale(clothingName: String, price: Double, platform: String, note: String) async {
        do {
            let log = SaleLogEntity(clothingID: nil, clothingName: clothingName, price: price, platform: platform, note: note)
            try await recordOutfitUseCase.recordSale(date: selectedDate, log: log)
            await loadEvents(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
