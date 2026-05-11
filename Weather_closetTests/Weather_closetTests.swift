import Testing
@testable import Weather_closet

struct Weather_closetTests {
    @Test func umbrellaRecommendationNone() {
        let useCase = CheckUmbrellaUseCase(repository: MockWeatherRepository(probability: 20))
        // Unit tests for domain logic go here
    }
}

// MARK: - Mocks
final class MockWeatherRepository: WeatherRepositoryProtocol {
    private let probability: Double
    init(probability: Double) { self.probability = probability }

    func fetchCurrentWeather(location: String) async throws -> WeatherEntity {
        WeatherEntity(
            location: location,
            temperature: 20,
            feelsLike: 18,
            humidity: 50,
            condition: .sunny,
            precipitationProbability: probability,
            precipitationAmount: 0,
            windSpeed: 5,
            forecast: [],
            fetchedAt: Date()
        )
    }

    func fetchForecast(location: String, days: Int) async throws -> [DailyForecast] { [] }
    func fetchRouteWeather(route: RouteWeatherEntity) async throws -> RouteWeatherEntity { route }
}
