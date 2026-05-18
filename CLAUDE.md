# Weather Closet — CLAUDE.md

## 프로젝트 개요

날씨 기반 옷장 관리 iOS 앱. 현재 날씨를 불러와 코디를 추천하고, 옷을 등록·관리·분석한다.

## 빌드 환경

- **Xcode 16**, **Swift 6**, iOS 17.0+
- 프로젝트 파일 생성: `xcodegen generate` (project.yml 기반)
- 패키지: RxSwift 6.7+, LookinServer (UI 인스펙터)

## 아키텍처

Clean Architecture + MVVM. 의존성 방향은 단방향.

```
Presentation → Domain ← Data ← Infrastructure
```

레이어별 상세 규칙은 각 디렉토리의 CLAUDE.md 참고:
- `Weather_closet/Domain/CLAUDE.md`
- `Weather_closet/Data/CLAUDE.md`
- `Weather_closet/Infrastructure/CLAUDE.md`
- `Weather_closet/Presentation/CLAUDE.md`
  - `Weather_closet/Presentation/Closet/CLAUDE.md`

## 탭 구성

| 탭 | 기능 |
|---|---|
| 홈 | 현재 날씨 + 코디 추천 |
| 옷장 | 옷 등록/수정/삭제, 카테고리 필터 |
| 캘린더 | 날짜별 착용 코디 기록 |
| 분석 | 착용 통계 |
| 프로필 | 사용자 설정 |

## 전역 규칙

- Swift 6 strict concurrency — UI 작업은 반드시 `@MainActor`
- `Task.sleep`으로 타이밍을 맞추지 말 것. dismiss 후 처리는 `onDismiss:` 콜백 또는 `dismiss(animated:completion:)` 사용
- DI: `AppDependencyContainer`에서 모든 의존성 생성, ViewModel 팩토리 메서드 제공
