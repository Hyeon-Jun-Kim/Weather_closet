# Infrastructure Layer

외부 시스템(파일시스템, CoreData, 네트워크, 디바이스 하드웨어)과의 접점.

## ImageStorageService

- 이미지는 `Documents/ClothingImages/`에 JPEG(압축률 0.8)로 저장
- DB/Entity에는 **파일명만** 저장 (`"uuid.jpg"`). 절대 경로 저장 금지 — 앱 재설치 시 경로가 바뀜
- `load(path:)`는 파일명과 레거시 절대 경로 모두 처리 (하위 호환)

## RemoveBgService

- Vision 프레임워크 `VNGenerateForegroundInstanceMaskRequest` 기반 **온디바이스** 처리
- 외부 API 없음. 네트워크 불필요
- 처리 비용이 크므로 `Task.detached(priority: .userInitiated)`로 백그라운드 실행

## PersistenceStack (CoreData)

- 앱 전체에서 단일 인스턴스 사용
- 모델 파일: `ClothingModel`, `UserModel`, `CalendarEventModel`
- 새 Entity 추가 시 `AppDependencyContainer`의 DataSource/Repository도 함께 연결

## LocationService

- `CLLocationManager` 래퍼. 날씨 요청 시 현재 좌표 제공
- 권한: `NSLocationWhenInUseUsageDescription` (Info.plist)
