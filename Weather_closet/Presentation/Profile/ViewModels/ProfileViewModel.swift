import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserEntity?
    @Published var bodyMeasurements: [BodyMeasurement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func loadProfile() async {
        isLoading = true
        do {
            user = try await userRepository.fetchUser()
            bodyMeasurements = try await userRepository.fetchBodyMeasurements()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProfile(nickname: String, profileImageURL: String?) async {
        guard var currentUser = user else {
            let newUser = UserEntity(nickname: nickname, profileImageURL: profileImageURL, bodyMeasurements: [])
            do {
                try await userRepository.saveUser(newUser)
                user = newUser
            } catch {
                errorMessage = error.localizedDescription
            }
            return
        }
        currentUser = UserEntity(nickname: nickname, profileImageURL: profileImageURL, bodyMeasurements: currentUser.bodyMeasurements)
        do {
            try await userRepository.saveUser(currentUser)
            user = currentUser
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addBodyMeasurement(height: Double, weight: Double) async {
        let measurement = BodyMeasurement(id: UUID(), recordedAt: Date(), height: height, weight: weight)
        do {
            try await userRepository.addBodyMeasurement(measurement)
            bodyMeasurements.insert(measurement, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
