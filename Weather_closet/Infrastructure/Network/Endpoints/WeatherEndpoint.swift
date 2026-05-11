import Foundation

// Uses Open-Meteo API (free, no API key required)
enum WeatherEndpoint: APIEndpoint {
    case current(location: String)
    case forecast(location: String, days: Int)

    var baseURL: String { "https://api.open-meteo.com" }

    var path: String { "/v1/forecast" }

    var method: HTTPMethod { .get }

    var headers: [String: String] { [:] }

    var queryItems: [URLQueryItem] {
        let coords = parseLocation(location)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "latitude", value: String(coords.lat)),
            URLQueryItem(name: "longitude", value: String(coords.lon)),
            URLQueryItem(name: "timezone", value: "Asia/Seoul"),
            URLQueryItem(name: "current", value: [
                "temperature_2m",
                "apparent_temperature",
                "relative_humidity_2m",
                "precipitation_probability",
                "precipitation",
                "wind_speed_10m",
                "weather_code"
            ].joined(separator: ",")),
        ]
        if case .forecast(_, let days) = self {
            items.append(URLQueryItem(name: "forecast_days", value: String(days)))
            items.append(URLQueryItem(name: "daily", value: [
                "temperature_2m_max",
                "temperature_2m_min",
                "weather_code",
                "precipitation_probability_max"
            ].joined(separator: ",")))
        }
        return items
    }

    private var location: String {
        switch self {
        case .current(let loc):    return loc
        case .forecast(let loc, _): return loc
        }
    }

    private func parseLocation(_ location: String) -> (lat: Double, lon: Double) {
        // Default to Seoul coordinates
        return (37.5665, 126.9780)
    }
}
