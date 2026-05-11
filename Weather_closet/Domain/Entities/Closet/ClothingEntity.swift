import Foundation

struct ClothingEntity: Identifiable {
    let id: UUID
    var name: String
    var brand: String
    var category: ClothingCategory
    var material: ClothingMaterial
    var color: String
    var size: ClothingSize
    var alterationHistory: [AlterationRecord]
    var rating: Int
    var review: String
    var wearCount: Int
    var purchaseDate: Date?
    var purchasePrice: Double?
    var purchasePlace: String
    var imageURLs: [String]
    var tags: [String]
    var isActive: Bool
}

enum ClothingCategory: String, CaseIterable {
    case outer = "아우터"
    case top = "상의"
    case bottom = "하의"
    case shirt = "셔츠"
    case jeans = "청바지"
    case dress = "원피스/드레스"
    case shoes = "신발"
    case accessory = "악세사리"
    case bag = "가방"
    case hat = "모자"
    case etc = "기타"
}

enum ClothingMaterial: String, CaseIterable {
    case leather = "레더"
    case wool = "울"
    case cotton = "면"
    case linen = "린넨"
    case denim = "데님"
    case polyester = "폴리에스터"
    case silk = "실크"
    case knit = "니트"
    case nylon = "나일론"
    case etc = "기타"
}

struct ClothingSize {
    var label: String
    var chest: Double?
    var shoulder: Double?
    var length: Double?
    var waist: Double?
    var hip: Double?
    var inseam: Double?
}

struct AlterationRecord {
    let id: UUID
    let date: Date
    let shop: String
    let description: String
    let cost: Double
}
