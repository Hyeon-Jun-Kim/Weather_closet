# Presentation Layer

SwiftUI + MVVM. 각 탭은 View/ViewModel 쌍으로 구성된다.

## ViewModel 규칙

- `@MainActor final class`, `ObservableObject` 준수
- UseCase를 생성자 주입으로 받음 (Protocol 타입)
- `@Published` 프로퍼티로 상태 노출

## View 규칙

- ViewModel은 `@EnvironmentObject`로 주입. `AppCoordinator`가 루트에서 주입
- sheet/fullScreenCover dismiss 후 후속 처리는 **`onDismiss:` 콜백** 또는 UIKit `dismiss(animated:completion:)` 사용
- `Task.sleep`으로 dismiss 타이밍을 맞추는 방식 금지

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
