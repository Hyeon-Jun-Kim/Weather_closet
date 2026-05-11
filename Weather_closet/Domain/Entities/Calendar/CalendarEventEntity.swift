import Foundation

struct CalendarEventEntity: Identifiable {
    let id: UUID
    let date: Date
    let type: CalendarEventType
}

enum CalendarEventType {
    case outfit(OutfitLogEntity)
    case purchase(PurchaseLogEntity)
    case sale(SaleLogEntity)
}

struct OutfitLogEntity {
    let outfitID: UUID?
    let clothingIDs: [UUID]
    let weather: WeatherSnapshot?
    let note: String
}

struct WeatherSnapshot {
    let temperature: Double
    let condition: WeatherCondition
    let precipitationProbability: Double
}

struct PurchaseLogEntity {
    let clothingID: UUID?
    let clothingName: String
    let price: Double
    let place: String
    let note: String
}

struct SaleLogEntity {
    let clothingID: UUID?
    let clothingName: String
    let price: Double
    let platform: String
    let note: String
}
