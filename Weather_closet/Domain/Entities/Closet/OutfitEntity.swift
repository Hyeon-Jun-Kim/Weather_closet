import Foundation

struct OutfitEntity: Identifiable {
    let id: UUID
    var name: String
    var clothingIDs: [UUID]
    var tags: [String]
    var note: String
    var createdAt: Date
    var imageURL: String?
}
