import Foundation
import SwiftData

@Model
final class UserModel {
    var nickname: String
    var profileImageURL: String?

    init(entity: UserEntity) {
        self.nickname = entity.nickname
        self.profileImageURL = entity.profileImageURL
    }

    func update(from entity: UserEntity) {
        nickname = entity.nickname
        profileImageURL = entity.profileImageURL
    }

    func toEntity() -> UserEntity {
        UserEntity(nickname: nickname, profileImageURL: profileImageURL, bodyMeasurements: [])
    }
}

@Model
final class BodyMeasurementModel {
    @Attribute(.unique) var id: UUID
    var recordedAt: Date
    var height: Double
    var weight: Double

    init(entity: BodyMeasurement) {
        self.id = entity.id
        self.recordedAt = entity.recordedAt
        self.height = entity.height
        self.weight = entity.weight
    }

    func toEntity() -> BodyMeasurement {
        BodyMeasurement(id: id, recordedAt: recordedAt, height: height, weight: weight)
    }
}
