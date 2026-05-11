import Foundation

@MainActor
final class WeatherRemoteDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCurrentWeather(location: String) async throws -> WeatherResponseDTO {
        let endpoint = WeatherEndpoint.current(location: location)
        return try await apiClient.request(endpoint)
    }

    func fetchForecast(location: String, days: Int) async throws -> [DailyForecastDTO] {
        let endpoint = WeatherEndpoint.forecast(location: location, days: days)
        let response: WeatherResponseDTO = try await apiClient.request(endpoint)
        guard let daily = response.daily else { return [] }
        return zip(daily.time.indices, daily.time).map { index, date in
            DailyForecastDTO(
                date: date,
                high: daily.temperatureMax[index],
                low: daily.temperatureMin[index],
                weatherCode: daily.weatherCode[index],
                precipitationProbability: daily.precipitationProbabilityMax[index]
            )
        }
    }
}
