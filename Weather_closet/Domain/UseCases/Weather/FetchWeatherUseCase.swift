import Foundation

@MainActor
final class FetchWeatherUseCase {
    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    func execute(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherEntity {
        try await repository.fetchCurrentWeather(latitude: latitude, longitude: longitude, locationName: locationName)
    }

    func executeForecast(latitude: Double, longitude: Double, days: Int = 7) async throws -> [DailyForecast] {
        try await repository.fetchForecast(latitude: latitude, longitude: longitude, days: days)
    }
}
