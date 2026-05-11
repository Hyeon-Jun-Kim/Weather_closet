import Foundation

@MainActor
final class WeatherRepository: WeatherRepositoryProtocol {
    private let remoteDataSource: WeatherRemoteDataSource

    init(remoteDataSource: WeatherRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchCurrentWeather(location: String) async throws -> WeatherEntity {
        let dto = try await remoteDataSource.fetchCurrentWeather(location: location)
        return dto.toEntity()
    }

    func fetchForecast(location: String, days: Int) async throws -> [DailyForecast] {
        let dto = try await remoteDataSource.fetchForecast(location: location, days: days)
        return dto.map { $0.toForecast() }
    }

    func fetchRouteWeather(route: RouteWeatherEntity) async throws -> RouteWeatherEntity {
        route
    }
}
