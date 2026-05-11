import Foundation

@MainActor
protocol UserRepositoryProtocol {
    func fetchUser() async throws -> UserEntity?
    func saveUser(_ user: UserEntity) async throws
    func addBodyMeasurement(_ measurement: BodyMeasurement) async throws
    func fetchBodyMeasurements() async throws -> [BodyMeasurement]
}
