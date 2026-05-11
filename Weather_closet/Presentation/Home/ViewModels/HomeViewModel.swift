import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var weather: WeatherEntity?
    @Published var forecast: [DailyForecast] = []
    @Published var umbrellaRecommendation: UmbrellaRecommendation = .none
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchWeatherUseCase: FetchWeatherUseCase
    private let checkUmbrellaUseCase: CheckUmbrellaUseCase
    let locationService: LocationService

    init(
        fetchWeatherUseCase: FetchWeatherUseCase,
        checkUmbrellaUseCase: CheckUmbrellaUseCase,
        locationService: LocationService
    ) {
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.checkUmbrellaUseCase = checkUmbrellaUseCase
        self.locationService = locationService
    }

    func loadWeather() async {
        isLoading = true
        errorMessage = nil

        if locationService.coordinate == nil {
            Log.d("HJHJ", "위치 요청 시작")
            locationService.requestLocation()
            // 위치 수신 대기
            var waited = 0
            while locationService.coordinate == nil && waited < 10 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                waited += 1
            }
        }

        guard let coordinate = locationService.coordinate else {
            Log.e("HJHJ", "위치 좌표 없음 - 날씨 로드 불가")
            errorMessage = "위치 정보를 가져올 수 없습니다."
            isLoading = false
            return
        }

        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let name = locationService.locationName

        Log.d("HJHJ", "날씨 로드 시작 - lat: \(lat), lon: \(lon), name: \(name)")
        do {
            async let weatherTask = fetchWeatherUseCase.execute(latitude: lat, longitude: lon, locationName: name)
            async let forecastTask = fetchWeatherUseCase.executeForecast(latitude: lat, longitude: lon)
            async let umbrellaTask = checkUmbrellaUseCase.execute(latitude: lat, longitude: lon)
            (weather, forecast, umbrellaRecommendation) = try await (weatherTask, forecastTask, umbrellaTask)
            Log.d("HJHJ", "날씨 로드 성공 - temp: \(weather?.temperature ?? 0)°C, forecast: \(forecast.count)일")
        } catch {
            Log.e("HJHJ", "날씨 로드 실패 - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
