import Foundation

@MainActor
final class WeatherRepository: WeatherRepositoryProtocol {
    private let remoteDataSource: WeatherRemoteDataSource

    init(remoteDataSource: WeatherRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchCurrentWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherEntity {
        let dto = try await remoteDataSource.fetchCurrentWeather(latitude: latitude, longitude: longitude)
        return dto.toEntity(locationName: locationName)
    }

    func fetchForecast(latitude: Double, longitude: Double, days: Int) async throws -> [DailyForecast] {
        let dto = try await remoteDataSource.fetchForecast(latitude: latitude, longitude: longitude, days: days)
        return dto.map { $0.toForecast() }
    }

    func fetchRouteWeather(route: RouteWeatherEntity) async throws -> RouteWeatherEntity {
        route
    }
}
