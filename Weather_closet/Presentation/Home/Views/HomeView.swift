import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let weather = viewModel.weather {
                        WeatherCardView(weather: weather, umbrella: viewModel.umbrellaRecommendation)
                        ForecastListView(forecasts: viewModel.forecast)
                    } else {
                        ContentUnavailableView(
                            "날씨 정보 없음",
                            systemImage: "cloud.slash",
                            description: Text("날씨 정보를 불러올 수 없습니다.")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("오늘의 날씨")
            .task { await viewModel.loadWeather() }
            .refreshable { await viewModel.loadWeather() }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct WeatherCardView: View {
    let weather: WeatherEntity
    let umbrella: UmbrellaRecommendation

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.location)
                        .font(.headline)
                    Text("\(Int(weather.temperature))°C")
                        .font(.system(size: 56, weight: .thin))
                    Text("체감 \(Int(weather.feelsLike))°C")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(weather.condition.iconName)
                        .font(.system(size: 50))
                    Label(umbrella.description, systemImage: umbrella.systemImageName)
                        .font(.caption)
                        .padding(6)
                        .background(umbrella == .none ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            Divider()
            HStack {
                WeatherInfoItem(title: "강수 확률", value: "\(Int(weather.precipitationProbability))%", icon: "drop.fill")
                Spacer()
                WeatherInfoItem(title: "습도", value: "\(weather.humidity)%", icon: "humidity.fill")
                Spacer()
                WeatherInfoItem(title: "풍속", value: "\(Int(weather.windSpeed))km/h", icon: "wind")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct WeatherInfoItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ForecastListView: View {
    let forecasts: [DailyForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주간 예보")
                .font(.headline)
            ForEach(forecasts, id: \.date) { forecast in
                HStack {
                    Text(forecast.date, format: .dateTime.weekday(.abbreviated))
                        .frame(width: 40, alignment: .leading)
                    Text(forecast.condition.iconName)
                    Spacer()
                    Text("\(Int(forecast.precipitationProbability))%")
                        .foregroundStyle(.blue)
                        .frame(width: 40)
                    Text("\(Int(forecast.low))° / \(Int(forecast.high))°")
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension WeatherCondition {
    var iconName: String {
        switch self {
        case .sunny:         return "☀️"
        case .partlyCloudy:  return "⛅️"
        case .cloudy:        return "☁️"
        case .rainy:         return "🌧️"
        case .snowy:         return "❄️"
        case .stormy:        return "⛈️"
        case .foggy:         return "🌫️"
        }
    }
}

extension UmbrellaRecommendation {
    var systemImageName: String {
        switch self {
        case .none:    return "checkmark.circle.fill"
        case .compact: return "umbrella"
        case .full:    return "umbrella.fill"
        }
    }
}
