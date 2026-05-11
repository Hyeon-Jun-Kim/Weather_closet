import Foundation

struct UserEntity {
    var nickname: String
    var profileImageURL: String?
    var bodyMeasurements: [BodyMeasurement]
}

struct BodyMeasurement: Identifiable {
    let id: UUID
    let recordedAt: Date
    let height: Double
    let weight: Double
}
