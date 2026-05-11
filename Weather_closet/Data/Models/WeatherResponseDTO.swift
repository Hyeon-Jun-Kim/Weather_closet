import Foundation

// Open-Meteo API response models
struct WeatherResponseDTO: Decodable {
    let current: CurrentWeatherDTO
    let daily: DailyWeatherDTO?
    let timezone: String
}

struct CurrentWeatherDTO: Decodable {
    let time: String
    let temperature2m: Double
    let apparentTemperature: Double
    let relativeHumidity2m: Int
    let precipitationProbability: Double?
    let precipitation: Double
    let windSpeed10m: Double
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity2m = "relative_humidity_2m"
        case precipitationProbability = "precipitation_probability"
        case precipitation
        case windSpeed10m = "wind_speed_10m"
        case weatherCode = "weather_code"
    }
}

struct DailyWeatherDTO: Decodable {
    let time: [String]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let weatherCode: [Int]
    let precipitationProbabilityMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case weatherCode = "weather_code"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

struct DailyForecastDTO: Decodable {
    let date: String
    let high: Double
    let low: Double
    let weatherCode: Int
    let precipitationProbability: Double

    func toForecast() -> DailyForecast {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return DailyForecast(
            date: formatter.date(from: date) ?? Date(),
            high: high,
            low: low,
            condition: WeatherCode(rawValue: weatherCode)?.toCondition() ?? .cloudy,
            precipitationProbability: precipitationProbability
        )
    }
}

extension WeatherResponseDTO {
    func toEntity() -> WeatherEntity {
        WeatherEntity(
            location: timezone,
            temperature: current.temperature2m,
            feelsLike: current.apparentTemperature,
            humidity: current.relativeHumidity2m,
            condition: WeatherCode(rawValue: current.weatherCode)?.toCondition() ?? .cloudy,
            precipitationProbability: current.precipitationProbability ?? 0,
            precipitationAmount: current.precipitation,
            windSpeed: current.windSpeed10m,
            forecast: [],
            fetchedAt: Date()
        )
    }
}

enum WeatherCode: Int {
    case clearSky = 0
    case partlyCloudy = 1, partlyCloudy2 = 2, overcast = 3
    case fog = 45, rimeFog = 48
    case lightDrizzle = 51, drizzle = 53, heavyDrizzle = 55
    case lightRain = 61, rain = 63, heavyRain = 65
    case lightSnow = 71, snow = 73, heavySnow = 75
    case thunderstorm = 95

    func toCondition() -> WeatherCondition {
        switch self {
        case .clearSky:                         return .sunny
        case .partlyCloudy, .partlyCloudy2:     return .partlyCloudy
        case .overcast:                         return .cloudy
        case .fog, .rimeFog:                    return .foggy
        case .lightDrizzle, .drizzle, .heavyDrizzle,
             .lightRain, .rain, .heavyRain:     return .rainy
        case .lightSnow, .snow, .heavySnow:     return .snowy
        case .thunderstorm:                     return .stormy
        }
    }
}
