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

## 규약 충돌 시 행동 원칙

작업 도중 기존 규약과 충돌하는 상황이 발생하면 — 내가 먼저 감지했든, 사용자가 규약에 어긋나는 작업을 요청했든 — 무조건 진행하지 말고 먼저 확인한다:

> "이 작업은 [해당 규약]과 충돌합니다. 규약을 업데이트할까요, 아니면 규약대로 진행할까요?"

규약을 업데이트하기로 했다면 작업 완료 후 관련 CLAUDE.md도 함께 수정한다.

## 전역 규칙

- Swift 6 strict concurrency — UI 작업은 반드시 `@MainActor`
- **이벤트 기반 처리**: `Task.sleep`으로 타이밍을 추측하지 말 것. 어떤 작업이든 "완료됐을 것이다"는 가정 대신 완료 이벤트를 직접 수신해 처리한다. 구체적인 대안은 `Presentation/CLAUDE.md` 참고
- DI: `AppDependencyContainer`에서 모든 의존성 생성, ViewModel 팩토리 메서드 제공
