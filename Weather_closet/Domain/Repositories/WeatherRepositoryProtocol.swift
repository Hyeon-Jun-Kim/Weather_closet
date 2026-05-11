import Foundation

@MainActor
protocol WeatherRepositoryProtocol {
    func fetchCurrentWeather(location: String) async throws -> WeatherEntity
    func fetchForecast(location: String, days: Int) async throws -> [DailyForecast]
    func fetchRouteWeather(route: RouteWeatherEntity) async throws -> RouteWeatherEntity
}
