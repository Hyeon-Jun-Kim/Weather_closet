import Foundation

@MainActor
final class CheckUmbrellaUseCase {
    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    func execute(location: String) async throws -> UmbrellaRecommendation {
        let weather = try await repository.fetchCurrentWeather(location: location)
        return recommendation(for: weather.precipitationProbability, amount: weather.precipitationAmount)
    }

    private func recommendation(for probability: Double, amount: Double) -> UmbrellaRecommendation {
        switch probability {
        case 0..<30:  return .none
        case 30..<60: return .compact
        default:      return .full
        }
    }
}
