import Foundation

enum WeatherEndpoint: APIEndpoint {
    case current(latitude: Double, longitude: Double)
    case forecast(latitude: Double, longitude: Double, days: Int)

    var baseURL: String { "https://api.open-meteo.com" }
    var path: String { "/v1/forecast" }
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }

    var queryItems: [URLQueryItem] {
        let (lat, lon) = coordinates
        var items: [URLQueryItem] = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "timezone", value: "auto"),
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
        if case .forecast(_, _, let days) = self {
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

    private var coordinates: (lat: Double, lon: Double) {
        switch self {
        case .current(let lat, let lon):      return (lat, lon)
        case .forecast(let lat, let lon, _):  return (lat, lon)
        }
    }
}
