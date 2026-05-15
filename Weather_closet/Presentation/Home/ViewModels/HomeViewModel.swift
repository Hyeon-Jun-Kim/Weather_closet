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
    let locationService: LocationService

    private var cancellables = Set<AnyCancellable>()
    private var weatherTask: Task<Void, Never>?

    init(
        fetchWeatherUseCase: FetchWeatherUseCase,
        locationService: LocationService
    ) {
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.locationService = locationService

        locationService.$coordinate
            .compactMap { $0 }
            .removeDuplicates {
                abs($0.latitude - $1.latitude) < 0.0001 && abs($0.longitude - $1.longitude) < 0.0001
            }
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.weatherTask?.cancel()
                    self.weatherTask = Task { await self.fetchWeather() }
                }
            }
            .store(in: &cancellables)
    }

    func loadWeather() async {
        if locationService.coordinate == nil {
            Log.d("HJHJ", "위치 요청 시작")
            isLoading = true
            locationService.requestLocation()
            return
        }
        weatherTask?.cancel()
        let task = Task { await fetchWeather() }
        weatherTask = task
        await task.value
    }

    private func fetchWeather() async {
        guard let coordinate = locationService.coordinate else { return }

        isLoading = true
        errorMessage = nil

        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let name = locationService.locationName

        Log.d("HJHJ", "날씨 로드 시작 - lat: \(lat), lon: \(lon), name: \(name)")
        do {
            async let weatherResult = fetchWeatherUseCase.execute(latitude: lat, longitude: lon, locationName: name)
            async let forecastResult = fetchWeatherUseCase.executeForecast(latitude: lat, longitude: lon)
            let (w, f) = try await (weatherResult, forecastResult)

            guard !Task.isCancelled else { isLoading = false; return }

            weather = w
            forecast = f
            umbrellaRecommendation = computeUmbrella(precipitationProbability: w.precipitationProbability)
            Log.d("HJHJ", "날씨 로드 성공 - temp: \(w.temperature)°C, forecast: \(f.count)일")
        } catch {
            guard !Task.isCancelled else { isLoading = false; return }
            Log.e("HJHJ", "날씨 로드 실패 - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func computeUmbrella(precipitationProbability: Double) -> UmbrellaRecommendation {
        switch precipitationProbability {
        case 0..<30:  return .none
        case 30..<60: return .compact
        default:      return .full
        }
    }
}
