import Foundation

@MainActor
final class WeatherRemoteDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherResponseDTO {
        Log.d("HJHJ", "현재 날씨 요청 - lat: \(latitude), lon: \(longitude)")
        let endpoint = WeatherEndpoint.current(latitude: latitude, longitude: longitude)
        do {
            let dto: WeatherResponseDTO = try await apiClient.request(endpoint)
            Log.d("HJHJ", "현재 날씨 응답 성공 - temp: \(dto.current.temperature2m)°C")
            return dto
        } catch {
            Log.e("HJHJ", "현재 날씨 요청 실패 - \(error)")
            throw error
        }
    }

    func fetchForecast(latitude: Double, longitude: Double, days: Int) async throws -> [DailyForecastDTO] {
        Log.d("HJHJ", "예보 요청 - lat: \(latitude), lon: \(longitude), days: \(days)")
        let endpoint = WeatherEndpoint.forecast(latitude: latitude, longitude: longitude, days: days)
        do {
            let response: WeatherResponseDTO = try await apiClient.request(endpoint)
            guard let daily = response.daily else {
                Log.w("HJHJ", "예보 응답에 daily 데이터 없음")
                return []
            }
            let result = zip(daily.time.indices, daily.time).map { index, date in
                DailyForecastDTO(
                    date: date,
                    high: daily.temperatureMax[index],
                    low: daily.temperatureMin[index],
                    weatherCode: daily.weatherCode[index],
                    precipitationProbability: daily.precipitationProbabilityMax[index]
                )
            }
            Log.d("HJHJ", "예보 응답 성공 - \(result.count)일치 데이터")
            return result
        } catch {
            Log.e("HJHJ", "예보 요청 실패 - \(error)")
            throw error
        }
    }
}
