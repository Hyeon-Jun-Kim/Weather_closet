import Foundation

struct WishlistItemEntity: Identifiable {
    let id: UUID
    var createdAt: Date
    var sortOrder: Int
    var name: String
    var brand: String
    var categoryRaw: String
    var price: Double?
    var imageURLs: [String]
    var goodPoint: String
    var badPoint: String
    var comparison: WishlistComparisonEntity?
}

struct WishlistComparisonEntity {
    var brand: String
    var categoryRaw: String
    var price: Double?
    var imageURLs: [String]
}
