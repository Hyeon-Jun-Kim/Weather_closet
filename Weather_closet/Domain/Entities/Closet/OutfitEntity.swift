import Foundation

struct CanvasItemState: Codable {
    var clothingID: UUID
    var offsetX: CGFloat
    var offsetY: CGFloat
    var scale: CGFloat
    var rotationRadians: Double
}

struct TextItemState: Codable {
    var text: String
    var colorIndex: Int
    var fontSize: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    var scale: CGFloat
    var rotationRadians: Double
}

struct OutfitEntity: Identifiable {
    let id: UUID
    var name: String
    var clothingIDs: [UUID]
    var canvasStates: [CanvasItemState]
    var textStates: [TextItemState]
    var tags: [String]
    var note: String
    var createdAt: Date
    var imageURL: String?
}
