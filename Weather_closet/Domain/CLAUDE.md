# Domain Layer

비즈니스 로직의 중심. 외부 프레임워크에 의존하지 않는다.

## 규칙

- **import는 Foundation만** 허용. UIKit, SwiftUI, CoreData 등 프레임워크 import 금지
- Entity는 `struct` 사용. 순수 데이터 모델이며 프레임워크 타입을 포함하지 않는다
- UseCase는 `execute()` 메서드 하나만 공개. 단일 책임
- Repository는 Protocol(`*RepositoryProtocol`)만 참조 — 구현체는 Data 레이어에 있음
- Domain은 Data/Infrastructure를 알지 못한다

## 구조

```
Domain/
├── Entities/        # 비즈니스 모델 (struct)
├── Repositories/    # Repository Protocol 정의
└── UseCases/        # 비즈니스 로직 (execute() 단일 진입점)
```

## Entity 변경 시

`ClothingEntity`를 수정하면 아래도 함께 확인:
- `Infrastructure/Persistence/ClothingModel.swift` (CoreData 모델 ↔ Entity 변환)
- `Presentation/Closet/Views/ClosetView.swift` (AddClothingView, EditClothingView 폼 필드)
