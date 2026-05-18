# Closet Feature

옷 등록·수정·삭제 및 이미지 관리 기능. `ClosetView.swift` 단일 파일에 모든 서브뷰가 포함된다.

## 이미지 등록 플로우

```
사용자 선택 (카메라 / 갤러리 / 웹검색)
    ↓ 이미지 취득
pendingImages 큐에 적재
    ↓
processNextBgIfIdle() — 큐에서 하나씩 꺼내 순차 처리
    ↓
presentBgPreview() — 배경 제거 미리보기 (UIKit present)
    ↓
onAccept → selectedImages에 추가 → processNextBgIfIdle() (다음 큐)
onCancel → 소스 다시 열기
onDismiss → 큐 초기화
```

## presentBgPreview / BgPreviewSession

- UIKit `present`를 직접 사용 (SwiftUI sheet으로 표현 불가한 전환 방식)
- `BgPreviewSession.dismiss`는 completion 클로저를 받음: `dismiss { afterWork() }`
  - 내부적으로 `vc.dismiss(animated:completion:)` 호출
  - completion에서 `onAccept`/`onCancel`/`onDismiss` 실행 → dismiss 애니메이션 완료 후 보장
- `presentBgPreview`는 `isBeingDismissed` VC를 건너뛰며 최대 15회 재시도하는 retry 로직 포함

## 소스 picker 닫힘 감지

| 소스 | 방법 |
|---|---|
| 카메라 (`fullScreenCover`) | `onDismiss:` 콜백 |
| 웹검색 (`sheet`) | `onDismiss:` 콜백 |
| 갤러리 (`photosPicker`) | `onChange(of: galleryItems)` — 전송 데이터 로딩 완료 후 처리 |

`Task.sleep`으로 타이밍 대기하지 말 것.

## AddClothingView / EditClothingView

- 동일한 이미지 등록 플로우를 각각 독립적으로 보유 (`pendingImages`, `processNextBgIfIdle` 중복)
- 공통 로직 추출 시 두 뷰 모두 수정 필요

## 커스텀 색상

`CustomColorStore` (UserDefaults 기반) 에서 관리. 앱 재설치 후에도 유지된다.
