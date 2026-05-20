import Foundation
import SwiftData

@Model
final class ClothingModel {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var name: String
    var brand: String
    var categoryRaw: String
    var subCategoryRaw: String = ""
    var materialRaw: String
    var color: String
    var sizeLabel: String
    var sizeShoulder: Double?
    var sizeChest: Double?
    var sizeSleeve: Double?
    var sizeLength: Double?
    var ratingValue: Double
    var review: String
    var wearCount: Int
    var purchaseDate: Date?
    var purchasePrice: Double?
    var purchasePlace: String
    var imageURLs: [String]
    var backgroundRemovedImageURL: String? = nil
    var tags: [String]
    var isActive: Bool

    @Relationship(deleteRule: .cascade) var alterations: [AlterationModel] = []

    init(entity: ClothingEntity) {
        self.id = entity.id
        self.createdAt = entity.createdAt
        self.name = entity.name
        self.brand = entity.brand
        self.categoryRaw = entity.category.rawValue
        self.subCategoryRaw = entity.subCategory
        self.materialRaw = entity.material.rawValue
        self.color = entity.color
        self.sizeLabel = entity.size.label
        self.sizeShoulder = entity.size.shoulder
        self.sizeChest = entity.size.chest
        self.sizeSleeve = entity.size.sleeve
        self.sizeLength = entity.size.length
        self.ratingValue = entity.rating
        self.review = entity.review
        self.wearCount = entity.wearCount
        self.purchaseDate = entity.purchaseDate
        self.purchasePrice = entity.purchasePrice
        self.purchasePlace = entity.purchasePlace
        self.imageURLs = entity.imageURLs
        self.backgroundRemovedImageURL = entity.backgroundRemovedImageURL
        self.tags = entity.tags
        self.isActive = entity.isActive
    }

    func update(from entity: ClothingEntity) {
        name = entity.name
        brand = entity.brand
        categoryRaw = entity.category.rawValue
        subCategoryRaw = entity.subCategory
        materialRaw = entity.material.rawValue
        color = entity.color
        sizeLabel = entity.size.label
        sizeShoulder = entity.size.shoulder
        sizeChest = entity.size.chest
        sizeSleeve = entity.size.sleeve
        sizeLength = entity.size.length
        ratingValue = entity.rating
        review = entity.review
        wearCount = entity.wearCount
        purchaseDate = entity.purchaseDate
        purchasePrice = entity.purchasePrice
        purchasePlace = entity.purchasePlace
        imageURLs = entity.imageURLs
        backgroundRemovedImageURL = entity.backgroundRemovedImageURL
        tags = entity.tags
        isActive = entity.isActive
    }

    func toEntity() -> ClothingEntity {
        ClothingEntity(
            id: id,
            createdAt: createdAt,
            name: name,
            brand: brand,
            category: ClothingCategory(rawValue: categoryRaw) ?? .etc,
            subCategory: subCategoryRaw,
            material: ClothingMaterial(rawValue: materialRaw) ?? .etc,
            color: color,
            size: ClothingSize(label: sizeLabel, shoulder: sizeShoulder, chest: sizeChest, sleeve: sizeSleeve, length: sizeLength),
            alterationHistory: alterations.map { $0.toEntity() },
            rating: ratingValue,
            review: review,
            wearCount: wearCount,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            purchasePlace: purchasePlace,
            imageURLs: imageURLs,
            backgroundRemovedImageURL: backgroundRemovedImageURL,
            tags: tags,
            isActive: isActive
        )
    }
}

@Model
final class AlterationModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var shop: String
    var alterationDescription: String
    var cost: Double

    init(entity: AlterationRecord) {
        self.id = entity.id
        self.date = entity.date
        self.shop = entity.shop
        self.alterationDescription = entity.description
        self.cost = entity.cost
    }

    func toEntity() -> AlterationRecord {
        AlterationRecord(id: id, date: date, shop: shop, description: alterationDescription, cost: cost)
    }
}

@Model
final class OutfitModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var clothingIDs: [UUID]
    var tags: [String]
    var note: String
    var createdAt: Date
    var imageURL: String?
    var canvasStatesData: Data?
    var textStatesData: Data?

    init(entity: OutfitEntity) {
        self.id = entity.id
        self.name = entity.name
        self.clothingIDs = entity.clothingIDs
        self.tags = entity.tags
        self.note = entity.note
        self.createdAt = entity.createdAt
        self.imageURL = entity.imageURL
        self.canvasStatesData = try? JSONEncoder().encode(entity.canvasStates)
        self.textStatesData = try? JSONEncoder().encode(entity.textStates)
    }

    func update(from entity: OutfitEntity) {
        name = entity.name
        clothingIDs = entity.clothingIDs
        tags = entity.tags
        note = entity.note
        imageURL = entity.imageURL
        canvasStatesData = try? JSONEncoder().encode(entity.canvasStates)
        textStatesData = try? JSONEncoder().encode(entity.textStates)
    }

    func toEntity() -> OutfitEntity {
        let canvasStates = canvasStatesData.flatMap { try? JSONDecoder().decode([CanvasItemState].self, from: $0) } ?? []
        let textStates = textStatesData.flatMap { try? JSONDecoder().decode([TextItemState].self, from: $0) } ?? []
        return OutfitEntity(
            id: id, name: name, clothingIDs: clothingIDs,
            canvasStates: canvasStates, textStates: textStates,
            tags: tags, note: note, createdAt: createdAt, imageURL: imageURL
        )
    }
}
