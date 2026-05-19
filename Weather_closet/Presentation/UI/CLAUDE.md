# UI 규약

Presentation 레이어 전반에 적용되는 UI 구현 규칙.

## 키보드 처리

**TextField가 포함된 View는 반드시 외부 탭 시 키보드를 닫아야 한다.**

```swift
// ScrollView / VStack 등 컨테이너에 적용
.onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
```

또는 View extension으로 공통 처리:

```swift
extension View {
    func hideKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
```

- Sheet / NavigationStack 내부에도 동일하게 적용
- List를 사용할 경우 `scrollDismissesKeyboard(.immediately)` 추가

## 레이아웃

- 옷장 그리드: 2열, 좌우 여백 16px, 아이템 간격 10px
- 카드 이미지: `Color.clear.aspectRatio(1, contentMode: .fit).overlay { Image... }` 패턴으로 1:1 비율 고정 (이미지 크기에 무관하게 일관된 셀 크기 유지)

## 이벤트 기반 처리

`Task.sleep`으로 타이밍을 추측하지 않는다. 구체적인 대안:

| 상황 | 방법 |
|---|---|
| sheet/fullScreenCover dismiss | `onDismiss:` 콜백 |
| UIKit VC dismiss | `dismiss(animated:completion:)` |
| PhotosPicker 완료 | `onChange(of: galleryItems)` |
| 비동기 완료 | `async/await` 또는 Combine |

## ViewModel 바인딩

- ViewModel은 `@EnvironmentObject`로 주입 (직접 생성 금지)
- `@Published` 프로퍼티로 상태 노출, View는 읽기 전용으로 소비
