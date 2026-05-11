import Foundation
import SwiftData

@Model
final class CalendarEventModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var eventTypeRaw: String
    var outfitIDsData: Data?
    var outfitNoteData: String?
    var purchaseClothingName: String?
    var purchasePrice: Double?
    var purchasePlace: String?
    var purchaseNote: String?
    var saleClothingName: String?
    var salePrice: Double?
    var salePlatform: String?
    var saleNote: String?

    init(entity: CalendarEventEntity) {
        self.id = entity.id
        self.date = entity.date
        switch entity.type {
        case .outfit(let log):
            self.eventTypeRaw = "outfit"
            self.outfitIDsData = try? JSONEncoder().encode(log.clothingIDs)
            self.outfitNoteData = log.note
        case .purchase(let log):
            self.eventTypeRaw = "purchase"
            self.purchaseClothingName = log.clothingName
            self.purchasePrice = log.price
            self.purchasePlace = log.place
            self.purchaseNote = log.note
        case .sale(let log):
            self.eventTypeRaw = "sale"
            self.saleClothingName = log.clothingName
            self.salePrice = log.price
            self.salePlatform = log.platform
            self.saleNote = log.note
        }
    }

    func update(from entity: CalendarEventEntity) {
        date = entity.date
        switch entity.type {
        case .outfit(let log):
            eventTypeRaw = "outfit"
            outfitIDsData = try? JSONEncoder().encode(log.clothingIDs)
            outfitNoteData = log.note
        case .purchase(let log):
            eventTypeRaw = "purchase"
            purchaseClothingName = log.clothingName
            purchasePrice = log.price
            purchasePlace = log.place
            purchaseNote = log.note
        case .sale(let log):
            eventTypeRaw = "sale"
            saleClothingName = log.clothingName
            salePrice = log.price
            salePlatform = log.platform
            saleNote = log.note
        }
    }

    func toEntity() -> CalendarEventEntity {
        let type: CalendarEventType
        switch eventTypeRaw {
        case "purchase":
            type = .purchase(PurchaseLogEntity(
                clothingID: nil,
                clothingName: purchaseClothingName ?? "",
                price: purchasePrice ?? 0,
                place: purchasePlace ?? "",
                note: purchaseNote ?? ""
            ))
        case "sale":
            type = .sale(SaleLogEntity(
                clothingID: nil,
                clothingName: saleClothingName ?? "",
                price: salePrice ?? 0,
                platform: salePlatform ?? "",
                note: saleNote ?? ""
            ))
        default:
            let clothingIDs = outfitIDsData.flatMap { try? JSONDecoder().decode([UUID].self, from: $0) } ?? []
            type = .outfit(OutfitLogEntity(
                outfitID: nil,
                clothingIDs: clothingIDs,
                weather: nil,
                note: outfitNoteData ?? ""
            ))
        }
        return CalendarEventEntity(id: id, date: date, type: type)
    }
}
