import Foundation
import SwiftData

@Model
final class WishlistItemModel {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var sortOrder: Int
    var name: String
    var brand: String
    var categoryRaw: String
    var price: Double?
    var imageURLs: [String]
    var goodPoint: String
    var badPoint: String
    // Comparison (nil fields = no comparison)
    var compBrand: String?
    var compCategoryRaw: String?
    var compPrice: Double?
    var compImageURLs: [String]

    init(entity: WishlistItemEntity) {
        self.id = entity.id
        self.createdAt = entity.createdAt
        self.sortOrder = entity.sortOrder
        self.name = entity.name
        self.brand = entity.brand
        self.categoryRaw = entity.categoryRaw
        self.price = entity.price
        self.imageURLs = entity.imageURLs
        self.goodPoint = entity.goodPoint
        self.badPoint = entity.badPoint
        self.compBrand = entity.comparison?.brand
        self.compCategoryRaw = entity.comparison?.categoryRaw
        self.compPrice = entity.comparison?.price
        self.compImageURLs = entity.comparison?.imageURLs ?? []
    }

    func update(from entity: WishlistItemEntity) {
        sortOrder = entity.sortOrder
        name = entity.name
        brand = entity.brand
        categoryRaw = entity.categoryRaw
        price = entity.price
        imageURLs = entity.imageURLs
        goodPoint = entity.goodPoint
        badPoint = entity.badPoint
        compBrand = entity.comparison?.brand
        compCategoryRaw = entity.comparison?.categoryRaw
        compPrice = entity.comparison?.price
        compImageURLs = entity.comparison?.imageURLs ?? []
    }

    func toEntity() -> WishlistItemEntity {
        let comp: WishlistComparisonEntity? = compBrand.map {
            WishlistComparisonEntity(
                brand: $0,
                categoryRaw: compCategoryRaw ?? "",
                price: compPrice,
                imageURLs: compImageURLs
            )
        }
        return WishlistItemEntity(
            id: id,
            createdAt: createdAt,
            sortOrder: sortOrder,
            name: name,
            brand: brand,
            categoryRaw: categoryRaw,
            price: price,
            imageURLs: imageURLs,
            goodPoint: goodPoint,
            badPoint: badPoint,
            comparison: comp
        )
    }
}
