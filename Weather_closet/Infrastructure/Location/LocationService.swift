import Foundation
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var locationName: String = ""
    @Published var isLoading = false
    @Published var error: Error?

    private let manager = CLLocationManager()
    nonisolated(unsafe) private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        Log.d("HJHJ", "위치 요청 - 현재 권한: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isLoading = true
            manager.requestLocation()
        default:
            Log.w("HJHJ", "위치 권한 없음 - 서울 기본값 사용")
            useFallback()
        }
    }

    private func useFallback() {
        coordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        locationName = "서울"
        isLoading = false
    }

    private func reverseGeocode(location: CLLocation) async {
        let name: String = await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                let result = placemarks?.first.flatMap {
                    $0.locality ?? $0.administrativeArea
                } ?? "현재 위치"
                continuation.resume(returning: result)
            }
        }
        locationName = name
        Log.d("HJHJ", "역지오코딩 성공 - \(name)")
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isLoading = true
                self.manager.requestLocation()
            case .denied, .restricted:
                Log.w("HJHJ", "위치 권한 거부 - 서울 기본값 사용")
                self.useFallback()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        Log.d("HJHJ", "위치 수신 - lat: \(lat), lon: \(lon)")
        let clLocation = location
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            await self.reverseGeocode(location: clLocation)
            self.isLoading = false
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Log.e("HJHJ", "위치 가져오기 실패 - \(message)")
        Task { @MainActor [weak self] in
            self?.useFallback()
        }
    }
}
