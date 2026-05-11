import Foundation

struct WeatherEntity {
    let location: String
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let condition: WeatherCondition
    let precipitationProbability: Double
    let precipitationAmount: Double
    let windSpeed: Double
    let forecast: [DailyForecast]
    let fetchedAt: Date
}

enum WeatherCondition {
    case sunny, partlyCloudy, cloudy, rainy, snowy, stormy, foggy
}

struct DailyForecast {
    let date: Date
    let high: Double
    let low: Double
    let condition: WeatherCondition
    let precipitationProbability: Double
}

enum UmbrellaRecommendation {
    case none
    case compact
    case full

    var description: String {
        switch self {
        case .none:    return "우산 불필요"
        case .compact: return "작은 우산 챙기세요"
        case .full:    return "큰 우산 챙기세요"
        }
    }
}

struct RouteWeatherEntity {
    let routeName: String
    let waypoints: [String]
    let schedule: RouteSchedule
    let weatherAlerts: [String]
    let umbrellaRecommendation: UmbrellaRecommendation
}

enum RouteSchedule {
    case weekday, weekend, both
}
