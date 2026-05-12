import Foundation

struct ClothingEntity: Identifiable {
    let id: UUID
    var name: String
    var brand: String
    var category: ClothingCategory
    var subCategory: String
    var material: ClothingMaterial
    var color: String
    var size: ClothingSize
    var alterationHistory: [AlterationRecord]
    var rating: Int
    var review: String
    var wearCount: Int
    var purchaseDate: Date?
    var purchasePrice: Double?
    var purchasePlace: String
    var imageURLs: [String]
    var tags: [String]
    var isActive: Bool
}

enum ClothingCategory: String, CaseIterable {
    case outer = "아우터"
    case top = "상의"
    case bottom = "하의"
    case dress = "원피스/드레스"
    case shoes = "신발"
    case accessory = "악세사리"
    case bag = "가방"
    case hat = "모자"
    case etc = "기타"

    var subCategories: [String] {
        switch self {
        case .outer:
            return [
                "후드 집업", "블루종/MA-1", "레더/라이더스 재킷", "슈트/블레이저 재킷",
                "카디건", "경량 패딩/패딩 베스트", "사파리/헌팅 재킷", "트러커 재킷",
                "스타디움 재킷", "나일론/코치 재킷", "트레이닝 재킷", "아노락 재킷",
                "플리스/뽀글이", "환절기 코트", "베스트", "무스탕/퍼",
                "겨울 코트", "패딩/헤비 아우터", "기타 아우터"
            ]
        case .top:
            return [
                "긴소매 티셔츠", "맨투맨/스웨트", "셔츠/블라우스", "후드 티셔츠",
                "반소매 티셔츠", "피케/카라 티셔츠", "니트/스웨터", "민소매 티셔츠", "기타 상의"
            ]
        case .bottom:
            return [
                "데님 팬츠", "트레이닝/조거 팬츠", "코튼 팬츠", "슈트 팬츠/슬랙스",
                "숏 팬츠", "레깅스", "점프 슈트/오버올", "기타 하의"
            ]
        case .dress:     return ["미니", "미디", "맥시", "기타"]
        case .shoes:     return ["스니커즈", "로퍼", "부츠", "샌들", "슬리퍼", "구두", "기타"]
        case .accessory: return ["목걸이", "귀걸이", "반지", "팔찌", "벨트", "선글라스", "시계", "기타"]
        case .bag:       return ["백팩", "토트백", "크로스백", "클러치", "기타"]
        case .hat:       return ["볼캡", "버킷햇", "비니", "페도라", "기타"]
        case .etc:       return ["기타"]
        }
    }
}

enum ClothingMaterial: String, CaseIterable {
    case leather = "레더"
    case wool = "울"
    case cotton = "면"
    case linen = "린넨"
    case denim = "데님"
    case polyester = "폴리에스터"
    case silk = "실크"
    case knit = "니트"
    case nylon = "나일론"
    case etc = "기타"
}

struct ClothingSize {
    var label: String
    var shoulder: Double?
    var chest: Double?
    var sleeve: Double?
    var length: Double?
    var waist: Double?
    var hip: Double?
    var inseam: Double?
}

struct AlterationRecord {
    let id: UUID
    let date: Date
    let shop: String
    let description: String
    let cost: Double
}
