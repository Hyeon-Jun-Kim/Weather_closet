# Presentation Layer

SwiftUI + MVVM. 각 탭은 View/ViewModel 쌍으로 구성된다.

## ViewModel 규칙

- `@MainActor final class`, `ObservableObject` 준수
- UseCase를 생성자 주입으로 받음 (Protocol 타입)
- `@Published` 프로퍼티로 상태 노출

## View 규칙

- ViewModel은 `@EnvironmentObject`로 주입. `AppCoordinator`가 루트에서 주입
- **이벤트 기반 처리 원칙 적용** (루트 CLAUDE.md 참고). Presentation에서 자주 쓰는 대안:
  - sheet/fullScreenCover dismiss → `onDismiss:` 콜백
  - UIKit VC dismiss → `dismiss(animated:completion:)`
  - PhotosPicker → `onChange(of: galleryItems)` (picker 닫힌 후 items 변경됨)
  - 비동기 작업 완료 → `async/await` 또는 Combine으로 완료 시점 수신

## 탭별 ViewModel 생성

`AppDependencyContainer`의 팩토리 메서드 사용:
- `makeHomeViewModel()`
- `makeClosetViewModel()`
- `makeCalendarViewModel()`
- `makeAnalysisViewModel()`
- `makeProfileViewModel()`

## 기능별 상세

복잡한 기능은 해당 디렉토리 CLAUDE.md 참고:
- `Closet/CLAUDE.md` — 이미지 등록/배경 제거 플로우
