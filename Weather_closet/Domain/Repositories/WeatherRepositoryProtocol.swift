import Foundation

@MainActor
protocol WeatherRepositoryProtocol {
    func fetchCurrentWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherEntity
    func fetchForecast(latitude: Double, longitude: Double, days: Int) async throws -> [DailyForecast]
    func fetchRouteWeather(route: RouteWeatherEntity) async throws -> RouteWeatherEntity
}
