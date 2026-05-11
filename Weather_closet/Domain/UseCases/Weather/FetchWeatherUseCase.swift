import Foundation

@MainActor
final class FetchWeatherUseCase {
    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    func execute(location: String) async throws -> WeatherEntity {
        try await repository.fetchCurrentWeather(location: location)
    }

    func executeForecast(location: String, days: Int = 7) async throws -> [DailyForecast] {
        try await repository.fetchForecast(location: location, days: days)
    }
}
