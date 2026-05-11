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

    var currentLocation = "Seoul"

    init(fetchWeatherUseCase: FetchWeatherUseCase, checkUmbrellaUseCase: CheckUmbrellaUseCase) {
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.checkUmbrellaUseCase = checkUmbrellaUseCase
    }

    func loadWeather() async {
        isLoading = true
        errorMessage = nil
        do {
            async let weatherTask = fetchWeatherUseCase.execute(location: currentLocation)
            async let forecastTask = fetchWeatherUseCase.executeForecast(location: currentLocation)
            async let umbrellaTask = checkUmbrellaUseCase.execute(location: currentLocation)
            (weather, forecast, umbrellaRecommendation) = try await (weatherTask, forecastTask, umbrellaTask)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
