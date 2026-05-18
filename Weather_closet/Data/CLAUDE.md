# Data Layer

Domain의 Repository Protocol을 구현한다.

## 규칙

- Repository 구현체는 반드시 `*RepositoryProtocol`을 준수
- DataSource를 통해서만 저장소에 접근. Repository가 CoreData/Network를 직접 건드리지 않는다
- CoreData 모델(`*Model`) ↔ Domain Entity 변환은 Repository 또는 DataSource 내부에서 처리
- DTO(Data/Models/)는 네트워크 응답 파싱 전용. Domain으로 올라갈 때는 Entity로 변환

## 구조

```
Data/
├── DataSources/
│   ├── Local/    # CoreData CRUD
│   └── Remote/   # API 호출
├── Models/       # 네트워크 응답 DTO (Decodable)
└── Repositories/ # Protocol 구현체
```
