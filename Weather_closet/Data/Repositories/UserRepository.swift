import Foundation

@MainActor
final class UserRepository: UserRepositoryProtocol {
    private let localDataSource: UserLocalDataSource

    init(localDataSource: UserLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func fetchUser() async throws -> UserEntity? {
        try await localDataSource.fetchUser()
    }

    func saveUser(_ user: UserEntity) async throws {
        try await localDataSource.saveUser(user)
    }

    func addBodyMeasurement(_ measurement: BodyMeasurement) async throws {
        try await localDataSource.addBodyMeasurement(measurement)
    }

    func fetchBodyMeasurements() async throws -> [BodyMeasurement] {
        try await localDataSource.fetchBodyMeasurements()
    }
}
