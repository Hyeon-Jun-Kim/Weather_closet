# Weather Closet — CLAUDE.md

## 프로젝트 개요

날씨 기반 옷장 관리 iOS 앱. 현재 날씨를 불러와 코디를 추천하고, 옷을 등록·관리·분석하는 기능을 제공한다.

## 빌드 및 환경

- **Xcode 16**, **Swift 6**, iOS 17.0+
- 프로젝트 파일 생성: `xcodegen generate` (project.yml 기반)
- 패키지 관리: Swift Package Manager
  - RxSwift 6.7+
  - LookinServer (디버그용 UI 인스펙터)
- 배경 제거: Vision 프레임워크 (`VNGenerateForegroundInstanceMaskRequest`) — 외부 API 없음
- 이미지 저장: `Documents/ClothingImages/` 에 JPEG로 저장, DB에는 파일명만 보관

## 아키텍처

Clean Architecture + MVVM

```
Presentation   →   Domain   ←   Data   ←   Infrastructure
(View/ViewModel)   (Entity/UseCase/Repository Protocol)   (Repository 구현/DataSource/Network/Persistence)
```

- **DI**: `AppDependencyContainer`가 모든 의존성을 생성하고 ViewModel 팩토리를 제공
- **상태 전달**: `@EnvironmentObject`로 ViewModel을 View 트리에 주입
- **동시성**: Swift Concurrency (`async/await`, `@MainActor`). RxSwift는 웹 이미지 검색 MutationObserver 처리에만 사용

## 주요 파일 위치

| 역할 | 경로 |
|---|---|
| DI 컨테이너 | `App/DI/AppDependencyContainer.swift` |
| 옷장 전체 UI | `Presentation/Closet/Views/ClosetView.swift` |
| 옷장 ViewModel | `Presentation/Closet/ViewModels/ClosetViewModel.swift` |
| 옷 엔티티 | `Domain/Entities/Closet/ClothingEntity.swift` |
| 이미지 저장 | `Infrastructure/Storage/ImageStorageService.swift` |
| 배경 제거 | `Infrastructure/Network/RemoveBgService.swift` |
| CoreData 스택 | `Infrastructure/Persistence/PersistenceStack.swift` |

## 코드 규칙

- Swift 6 strict concurrency. UI 작업은 반드시 `@MainActor`
- UIKit 직접 present가 필요한 경우 `presentBgPreview()` 패턴 참고 — 이미 dismiss 중인 VC를 건너뛰는 retry 로직 포함
- sheet/fullScreenCover dismiss 후 작업이 필요하면 `onDismiss:` 콜백 또는 `dismiss(animated:completion:)` 사용. `Task.sleep` 으로 대기하지 말 것
- 이미지 경로는 파일명만 저장. 절대 경로 저장 금지 (앱 재설치 시 경로 변경됨)
- 커스텀 색상은 `UserDefaults`의 `CustomColorStore`에서 관리

## 탭 구성

- **홈**: 현재 날씨 + 코디 추천
- **옷장**: 옷 등록/수정/삭제, 카테고리 필터, 배경 제거 미리보기
- **캘린더**: 날짜별 착용 코디 기록
- **분석**: 착용 통계
- **프로필**: 사용자 설정
