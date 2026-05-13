import SwiftUI
import PhotosUI

enum ClosetMainTab: Hashable, CaseIterable {
    case closet, wishlist, outfit
    var title: String {
        switch self {
        case .closet:   return "옷장"
        case .wishlist: return "위시리스트"
        case .outfit:   return "코디"
        }
    }
}

struct ClosetView: View {
    @EnvironmentObject var viewModel: ClosetViewModel
    @State private var showAddSheet = false
    @State private var selectedTab: ClosetMainTab = .closet

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    ClosetTabSelector(selectedTab: $selectedTab)

                    TabView(selection: $selectedTab) {
                        VStack(spacing: 0) { closetContent }
                            .tag(ClosetMainTab.closet)

                        ContentUnavailableView(
                            "위시리스트",
                            systemImage: "heart",
                            description: Text("준비 중입니다.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(ClosetMainTab.wishlist)

                        ContentUnavailableView(
                            "코디",
                            systemImage: "person.crop.rectangle.stack",
                            description: Text("준비 중입니다.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(ClosetMainTab.outfit)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }

                if selectedTab == .closet {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray).opacity(0.85), in: Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadClothing() }
            .sheet(isPresented: $showAddSheet) {
                AddClothingView()
                    .environmentObject(viewModel)
            }
        }
    }

    @ViewBuilder
    private var closetContent: some View {
        CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
            .onChange(of: viewModel.selectedCategory) { _, _ in
                viewModel.selectedSubCategory = nil
            }

        if !viewModel.availableSubCategories.isEmpty {
            SubCategoryFilterView(
                subCategories: viewModel.availableSubCategories,
                selectedSubCategory: $viewModel.selectedSubCategory
            )
        }

        if viewModel.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredList.isEmpty {
            ContentUnavailableView(
                "옷이 없습니다",
                systemImage: "tshirt",
                description: Text("옷장에 옷을 추가해보세요.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ClothingGridView(items: viewModel.filteredList)
                .environmentObject(viewModel)
        }
    }
}

struct ClosetTabSelector: View {
    @Binding var selectedTab: ClosetMainTab

    var body: some View {
        HStack(spacing: 28) {
            ForEach(ClosetMainTab.allCases, id: \.title) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.title)
                        .font(.system(size: isSelected ? 22 : 18, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? Color(.label) : Color(.label).opacity(0.3))
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Category Filter

struct CategoryFilterView: View {
    @Binding var selectedCategory: ClothingCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "전체", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    CategoryChip(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct SubCategoryFilterView: View {
    let subCategories: [String]
    @Binding var selectedSubCategory: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "전체", isSelected: selectedSubCategory == nil) {
                    selectedSubCategory = nil
                }
                ForEach(subCategories, id: \.self) { sub in
                    CategoryChip(title: sub, isSelected: selectedSubCategory == sub) {
                        selectedSubCategory = (selectedSubCategory == sub) ? nil : sub
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(Color.secondary.opacity(0.06))
    }
}

// MARK: - Grid

struct ClothingGridView: View {
    @EnvironmentObject var viewModel: ClosetViewModel
    let items: [ClothingEntity]
    let columns = [GridItem(.adaptive(minimum: 160))]

    @State private var itemToEdit: ClothingEntity?
    @State private var itemToDelete: ClothingEntity?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    NavigationLink(destination: ClothingDetailView(clothing: item)) {
                        ClothingCard(clothing: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            itemToEdit = item
                        } label: {
                            Label("수정", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            itemToDelete = item
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .alert("삭제", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("삭제", role: .destructive) {
                if let item = itemToDelete {
                    Task { await viewModel.deleteClothing(id: item.id) }
                    itemToDelete = nil
                }
            }
            Button("취소", role: .cancel) { itemToDelete = nil }
        } message: {
            if let name = itemToDelete?.name {
                Text("'\(name)'을(를) 삭제하시겠습니까?")
            }
        }
        .sheet(item: $itemToEdit) { item in
            EditClothingView(clothing: item)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Card

struct ClothingCard: View {
    let clothing: ClothingEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let path = clothing.imageURLs.first,
                   let image = ImageStorageService.shared.load(path: path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.secondary.opacity(0.15)
                        .overlay {
                            Image(systemName: "tshirt")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(clothing.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(clothing.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(clothing.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                    Spacer()
                    Text(String(repeating: "⭐️", count: max(0, min(clothing.rating, 5))))
                        .font(.caption2)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Detail

struct ClothingDetailView: View {
    let clothing: ClothingEntity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ClothingImageCarousel(paths: clothing.imageURLs)
                Group {
                    InfoSection(title: "기본 정보") {
                        InfoRow(label: "브랜드", value: clothing.brand)
                        InfoRow(label: "카테고리", value: clothing.category.rawValue)
                        if !clothing.subCategory.isEmpty {
                            InfoRow(label: "세부 카테고리", value: clothing.subCategory)
                        }
                        InfoRow(label: "소재", value: clothing.material.rawValue)
                        InfoRow(label: "색상", value: clothing.color)
                    }
                    InfoSection(title: "사이즈") {
                        InfoRow(label: "표기 사이즈", value: clothing.size.label.isEmpty ? "-" : clothing.size.label)
                        if let v = clothing.size.shoulder { InfoRow(label: "어깨단면", value: "\(v)cm") }
                        if let v = clothing.size.chest    { InfoRow(label: "가슴단면", value: "\(v)cm") }
                        if let v = clothing.size.sleeve   { InfoRow(label: "소매길이", value: "\(v)cm") }
                        if let v = clothing.size.length   { InfoRow(label: "총장",    value: "\(v)cm") }
                    }
                    InfoSection(title: "착용 정보") {
                        InfoRow(label: "착용 횟수", value: "\(clothing.wearCount)회")
                        InfoRow(label: "만족도", value: "\(clothing.rating)점")
                    }
                    if clothing.purchasePrice != nil || !clothing.purchasePlace.isEmpty {
                        InfoSection(title: "구매 정보") {
                            if let price = clothing.purchasePrice {
                                InfoRow(label: "구매가", value: "\(Int(price).formatted())원")
                            }
                            if !clothing.purchasePlace.isEmpty {
                                if let url = URL(string: clothing.purchasePlace),
                                   url.scheme == "http" || url.scheme == "https" {
                                    Button {
                                        UIApplication.shared.open(url)
                                    } label: {
                                        Text("제품 링크 바로가기")
                                            .font(.subheadline)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                } else {
                                    InfoRow(label: "제품 링크", value: clothing.purchasePlace)
                                }
                            }
                        }
                    }
                    if !clothing.review.isEmpty {
                        InfoSection(title: "한줄평") {
                            Text(clothing.review).font(.body)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(clothing.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ClothingImageCarousel: View {
    let paths: [String]

    var body: some View {
        if paths.isEmpty {
            emptyImagePlaceholder
        } else {
            TabView {
                ForEach(paths, id: \.self) { path in
                    if let image = ImageStorageService.shared.load(path: path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    }
                }
            }
            .tabViewStyle(.page)
            .frame(maxWidth: .infinity)
            .frame(height: 320)
        }
    }

    private var emptyImagePlaceholder: some View {
        Color.secondary.opacity(0.1)
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .overlay {
                Image(systemName: "tshirt")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Color Picker

struct ClothingColor: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    var isCustom: Bool = false
    var imagePath: String? = nil
}

private enum CustomColorStore {
    private static let namesKey  = "customClothingColorNames"
    private static let imagesKey = "customClothingColorImages"

    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: namesKey) ?? []
    }

    static func loadEntries() -> [(name: String, imagePath: String?)] {
        let names  = load()
        let images = UserDefaults.standard.dictionary(forKey: imagesKey) as? [String: String] ?? [:]
        return names.map { (name: $0, imagePath: images[$0]) }
    }

    static func add(_ name: String, imagePath: String? = nil) {
        var list = load()
        guard !list.contains(name) else { return }
        list.append(name)
        UserDefaults.standard.set(list, forKey: namesKey)
        if let path = imagePath {
            var images = UserDefaults.standard.dictionary(forKey: imagesKey) as? [String: String] ?? [:]
            images[name] = path
            UserDefaults.standard.set(images, forKey: imagesKey)
        }
    }

    static func remove(_ name: String) {
        var list = load()
        list.removeAll { $0 == name }
        UserDefaults.standard.set(list, forKey: namesKey)
        var images = UserDefaults.standard.dictionary(forKey: imagesKey) as? [String: String] ?? [:]
        images.removeValue(forKey: name)
        UserDefaults.standard.set(images, forKey: imagesKey)
    }
}

private let clothingColors: [ClothingColor] = [
    // Achromatic
    .init(name: "블랙",       color: Color(white: 0.08)),
    .init(name: "챠콜",       color: Color(white: 0.22)),
    .init(name: "다크 그레이",  color: Color(white: 0.35)),
    .init(name: "그레이",      color: Color(white: 0.55)),
    .init(name: "라이트 그레이", color: Color(white: 0.78)),
    .init(name: "오프화이트",   color: Color(white: 0.92)),
    .init(name: "화이트",      color: Color(white: 0.95)),
    // Warm Neutrals
    .init(name: "아이보리",    color: Color(red: 0.98, green: 0.96, blue: 0.90)),
    .init(name: "크림",       color: Color(red: 0.97, green: 0.93, blue: 0.82)),
    .init(name: "베이지",      color: Color(red: 0.93, green: 0.86, blue: 0.73)),
    .init(name: "탄",         color: Color(red: 0.82, green: 0.71, blue: 0.55)),
    // Browns
    .init(name: "카멜",       color: Color(red: 0.76, green: 0.55, blue: 0.26)),
    .init(name: "브라운",      color: Color(red: 0.45, green: 0.25, blue: 0.12)),
    .init(name: "초콜렛",      color: Color(red: 0.22, green: 0.11, blue: 0.04)),
    // Reds
    .init(name: "와인",       color: Color(red: 0.35, green: 0.02, blue: 0.08)),
    .init(name: "버건디",      color: Color(red: 0.50, green: 0.00, blue: 0.13)),
    .init(name: "레드",       color: Color(red: 0.95, green: 0.07, blue: 0.07)),
    .init(name: "코랄",       color: Color(red: 1.00, green: 0.50, blue: 0.31)),
    .init(name: "살몬",       color: Color(red: 0.98, green: 0.59, blue: 0.48)),
    // Pinks
    .init(name: "핑크",       color: Color(red: 1.00, green: 0.60, blue: 0.75)),
    .init(name: "로즈",       color: Color(red: 0.88, green: 0.40, blue: 0.51)),
    .init(name: "라일락",      color: Color(red: 0.83, green: 0.72, blue: 0.87)),
    .init(name: "라벤더",      color: Color(red: 0.71, green: 0.61, blue: 0.86)),
    // Purples
    .init(name: "바이올렛",    color: Color(red: 0.56, green: 0.00, blue: 0.75)),
    .init(name: "퍼플",       color: Color(red: 0.58, green: 0.10, blue: 0.75)),
    .init(name: "마젠타",      color: Color(red: 0.85, green: 0.00, blue: 0.60)),
    // Oranges
    .init(name: "테라코타",    color: Color(red: 0.79, green: 0.38, blue: 0.28)),
    .init(name: "오렌지",      color: Color(red: 1.00, green: 0.58, blue: 0.00)),
    // Yellows
    .init(name: "머스타드",    color: Color(red: 0.72, green: 0.52, blue: 0.04)),
    .init(name: "옐로우",      color: Color(red: 1.00, green: 0.84, blue: 0.00)),
    .init(name: "골드",       color: Color(red: 0.85, green: 0.65, blue: 0.13)),
    // Greens
    .init(name: "민트",       color: Color(red: 0.55, green: 0.88, blue: 0.80)),
    .init(name: "세이지",      color: Color(red: 0.55, green: 0.65, blue: 0.51)),
    .init(name: "에메랄드",    color: Color(red: 0.05, green: 0.60, blue: 0.40)),
    .init(name: "카키",       color: Color(red: 0.46, green: 0.47, blue: 0.26)),
    .init(name: "올리브",      color: Color(red: 0.40, green: 0.40, blue: 0.13)),
    .init(name: "그린",       color: Color(red: 0.18, green: 0.55, blue: 0.25)),
    .init(name: "포레스트 그린", color: Color(red: 0.13, green: 0.37, blue: 0.13)),
    // Blues / Teals / Indigos
    .init(name: "틸",         color: Color(red: 0.00, green: 0.50, blue: 0.50)),
    .init(name: "스카이블루",   color: Color(red: 0.53, green: 0.81, blue: 0.98)),
    .init(name: "라이트 인디고", color: Color(red: 0.63, green: 0.76, blue: 0.88)),
    .init(name: "블루",       color: Color(red: 0.00, green: 0.48, blue: 1.00)),
    .init(name: "코발트",      color: Color(red: 0.00, green: 0.28, blue: 0.73)),
    .init(name: "워시드 인디고", color: Color(red: 0.35, green: 0.48, blue: 0.67)),
    .init(name: "인디고",      color: Color(red: 0.22, green: 0.29, blue: 0.51)),
    .init(name: "네이비",      color: Color(red: 0.05, green: 0.10, blue: 0.30)),
    // Special
    .init(name: "멀티",       color: .clear),
]

struct ColorPickerRow: View {
    @Binding var selectedColor: String
    var images: [UIImage] = []
    @State private var searchText = ""
    @State private var showPalette = false
    @State private var showImagePicker = false
    @State private var customColorEntries: [(name: String, imagePath: String?)] = CustomColorStore.loadEntries()

    private var allColors: [ClothingColor] {
        clothingColors + customColorEntries.map { ClothingColor(name: $0.name, color: .secondary, isCustom: true, imagePath: $0.imagePath) }
    }

    private var suggestions: [ClothingColor] {
        guard !searchText.isEmpty else { return [] }
        return allColors.filter { $0.name.localizedStandardContains(searchText) }
    }

    private var canAddCustom: Bool {
        !searchText.isEmpty && !allColors.contains(where: { $0.name == searchText })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let matched = allColors.first(where: { $0.name == selectedColor }) {
                    ColorCircle(item: matched, size: 24, isSelected: false)
                }
                TextField("색상 직접 입력", text: $searchText)
                    .onChange(of: searchText) { _, text in
                        if selectedColor != text { selectedColor = text }
                    }
                if !images.isEmpty {
                    Button { showImagePicker = true } label: {
                        Image(systemName: "eyedropper")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                Button { showPalette = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }

            if !suggestions.isEmpty || canAddCustom {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(suggestions) { item in
                            Button {
                                selectedColor = item.name
                                searchText = item.name
                            } label: {
                                VStack(spacing: 4) {
                                    ColorCircle(item: item, size: 38, isSelected: selectedColor == item.name)
                                    Text(item.name)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if canAddCustom {
                            Button {
                                CustomColorStore.add(searchText)
                                customColorEntries = CustomColorStore.loadEntries()
                                selectedColor = searchText
                            } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                            .foregroundStyle(Color.accentColor)
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                    .frame(width: 38, height: 38)
                                    Text("추가")
                                        .font(.caption2)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            if !selectedColor.isEmpty, searchText != selectedColor {
                searchText = selectedColor
            }
        }
        .onChange(of: selectedColor) { _, newValue in
            if searchText != newValue { searchText = newValue }
            customColorEntries = CustomColorStore.loadEntries()
        }
        .sheet(isPresented: $showPalette) {
            ColorPaletteSheet(selectedColor: $selectedColor) { name in
                searchText = name
            }
            .onDisappear { customColorEntries = CustomColorStore.loadEntries() }
        }
        .fullScreenCover(isPresented: $showImagePicker) {
            ImageColorPickerSheet(images: images) { name in
                selectedColor = name
                searchText = name
            }
        }
    }
}

struct ColorCircle: View {
    let item: ClothingColor
    let size: CGFloat
    let isSelected: Bool
    @State private var customImage: UIImage?

    private var isLight: Bool {
        ["화이트", "오프화이트", "아이보리", "크림", "베이지", "탄",
         "라이트 그레이", "옐로우", "골드", "민트", "스카이블루",
         "라이트 인디고", "살몬", "코랄", "핑크", "라일락", "라벤더"].contains(item.name)
    }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
            Group {
                if item.isCustom {
                    if let img = customImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.12))
                            .overlay(
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .foregroundStyle(Color.secondary.opacity(0.6))
                            )
                            .overlay(
                                Text(String(item.name.prefix(1)))
                                    .font(.system(size: size * 0.32, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                            )
                    }
                } else if item.name == "멀티" {
                    Circle()
                        .fill(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center))
                } else {
                    Circle().fill(item.color)
                }
            }
            .padding(isSelected ? 3 : 0)
            if item.name == "화이트" {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.5)
                    .padding(isSelected ? 3 : 0)
            }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(isLight ? Color.black.opacity(0.7) : .white)
            }
        }
        .frame(width: size, height: size)
        .task(id: item.imagePath ?? "") {
            if let path = item.imagePath {
                customImage = ImageStorageService.shared.load(path: path)
            } else {
                customImage = nil
            }
        }
    }
}

struct ColorPaletteSheet: View {
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    @State private var customColorEntries: [(name: String, imagePath: String?)] = CustomColorStore.loadEntries()
    @State private var searchText = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    private var filteredClothingColors: [ClothingColor] {
        guard !searchText.isEmpty else { return clothingColors }
        return clothingColors.filter { $0.name.localizedStandardContains(searchText) }
    }

    private var filteredCustomEntries: [(name: String, imagePath: String?)] {
        guard !searchText.isEmpty else { return customColorEntries }
        return customColorEntries.filter { $0.name.localizedStandardContains(searchText) }
    }

    private var hasNoResults: Bool {
        filteredClothingColors.isEmpty && filteredCustomEntries.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(filteredClothingColors) { item in
                        Button {
                            selectedColor = item.name
                            onSelect(item.name)
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                ColorCircle(item: item, size: 52, isSelected: selectedColor == item.name)
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, minHeight: 16, alignment: .top)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()

                if !filteredCustomEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("나만의 색상")
                            .font(.headline)
                            .padding(.horizontal)
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(filteredCustomEntries, id: \.name) { entry in
                                let item = ClothingColor(name: entry.name, color: .secondary, isCustom: true, imagePath: entry.imagePath)
                                Button {
                                    selectedColor = entry.name
                                    onSelect(entry.name)
                                    dismiss()
                                } label: {
                                    VStack(spacing: 6) {
                                        ColorCircle(item: item, size: 52, isSelected: selectedColor == entry.name)
                                        Text(entry.name)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, minHeight: 16, alignment: .top)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        CustomColorStore.remove(entry.name)
                                        customColorEntries = CustomColorStore.loadEntries()
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }

                if hasNoResults {
                    Text("'\(searchText)'에 해당하는 색상이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .searchable(text: $searchText, prompt: "색상 검색")
            .navigationTitle("색상 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}

// UIKit 기반 gesture overlay — 핀치·2손가락 팬·1손가락 드래그 분리
private final class _TouchView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

private struct ImageGestureOverlay: UIViewRepresentable {
    var onPinchDelta: (CGFloat) -> Void
    var onTwoFingerPan: (CGSize) -> Void
    var onSingleDrag: (CGPoint) -> Void

    func makeUIView(context: Context) -> _TouchView {
        let view = _TouchView()
        view.backgroundColor = .clear

        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.pinched(_:)))
        let twoPan = UIPanGestureRecognizer(target: context.coordinator,
                                            action: #selector(Coordinator.twoPanned(_:)))
        twoPan.minimumNumberOfTouches = 2
        twoPan.maximumNumberOfTouches = 2
        let onePan = UIPanGestureRecognizer(target: context.coordinator,
                                            action: #selector(Coordinator.singleDragged(_:)))
        onePan.maximumNumberOfTouches = 1

        for g in [pinch, twoPan, onePan] as [UIGestureRecognizer] {
            g.delegate = context.coordinator
            view.addGestureRecognizer(g)
        }
        return view
    }

    func updateUIView(_ uiView: _TouchView, context: Context) {
        let c = context.coordinator
        c.onPinchDelta   = onPinchDelta
        c.onTwoFingerPan = onTwoFingerPan
        c.onSingleDrag   = onSingleDrag
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPinchDelta: onPinchDelta,
                    onTwoFingerPan: onTwoFingerPan,
                    onSingleDrag: onSingleDrag)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPinchDelta: (CGFloat) -> Void
        var onTwoFingerPan: (CGSize) -> Void
        var onSingleDrag: (CGPoint) -> Void
        private var lastPinchScale: CGFloat = 1

        init(onPinchDelta: @escaping (CGFloat) -> Void,
             onTwoFingerPan: @escaping (CGSize) -> Void,
             onSingleDrag: @escaping (CGPoint) -> Void) {
            self.onPinchDelta   = onPinchDelta
            self.onTwoFingerPan = onTwoFingerPan
            self.onSingleDrag   = onSingleDrag
        }

        @objc func pinched(_ r: UIPinchGestureRecognizer) {
            switch r.state {
            case .began:   lastPinchScale = 1
            case .changed:
                let delta = r.scale / lastPinchScale
                lastPinchScale = r.scale
                onPinchDelta(delta)
            default: break
            }
        }

        @objc func twoPanned(_ r: UIPanGestureRecognizer) {
            guard r.state == .changed else { return }
            let t = r.translation(in: r.view)
            onTwoFingerPan(CGSize(width: t.x, height: t.y))
            r.setTranslation(.zero, in: r.view)
        }

        @objc func singleDragged(_ r: UIPanGestureRecognizer) {
            guard r.state == .began || r.state == .changed else { return }
            onSingleDrag(r.location(in: r.view))
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

// CropPassThroughView: UIKit 터치를 직접 받되, 핸들 근처는 nil 반환해 하위 SwiftUI 뷰로 통과
private final class CropPassThroughView: UIView {
    var handlePositions: [CGPoint] = []
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        for pos in handlePositions {
            let dx = point.x - pos.x
            let dy = point.y - pos.y
            if dx*dx + dy*dy < 900 { return nil }  // 30pt radius: pass through to handle below
        }
        return self
    }
}

// ZStack 맨 위에 배치해 다크 영역 포함 전체에서 pinch/pan을 받음
private struct CropGestureView: UIViewRepresentable {
    var onPinchDelta: (CGFloat) -> Void
    var onPanDelta: (CGSize) -> Void
    var onTwoFingerPanDelta: (CGSize) -> Void
    var handlePositions: [CGPoint]

    func makeUIView(context: Context) -> CropPassThroughView {
        let v = CropPassThroughView()
        v.backgroundColor = .clear
        v.isMultipleTouchEnabled = true
        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.pinched(_:)))
        pinch.delegate = context.coordinator
        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.panned(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        let twoFingerPan = UIPanGestureRecognizer(target: context.coordinator,
                                                  action: #selector(Coordinator.twoFingerPanned(_:)))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        twoFingerPan.delegate = context.coordinator
        v.addGestureRecognizer(pinch)
        v.addGestureRecognizer(pan)
        v.addGestureRecognizer(twoFingerPan)
        return v
    }

    func updateUIView(_ uiView: CropPassThroughView, context: Context) {
        uiView.handlePositions = handlePositions
        context.coordinator.onPinchDelta = onPinchDelta
        context.coordinator.onPanDelta = onPanDelta
        context.coordinator.onTwoFingerPanDelta = onTwoFingerPanDelta
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPinchDelta: onPinchDelta, onPanDelta: onPanDelta, onTwoFingerPanDelta: onTwoFingerPanDelta)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPinchDelta: (CGFloat) -> Void
        var onPanDelta: (CGSize) -> Void
        var onTwoFingerPanDelta: (CGSize) -> Void
        private var lastScale: CGFloat = 1

        init(onPinchDelta: @escaping (CGFloat) -> Void,
             onPanDelta: @escaping (CGSize) -> Void,
             onTwoFingerPanDelta: @escaping (CGSize) -> Void) {
            self.onPinchDelta = onPinchDelta
            self.onPanDelta = onPanDelta
            self.onTwoFingerPanDelta = onTwoFingerPanDelta
        }

        @objc func pinched(_ r: UIPinchGestureRecognizer) {
            switch r.state {
            case .began:   lastScale = 1
            case .changed:
                let delta = r.scale / lastScale
                lastScale = r.scale
                onPinchDelta(delta)
            default: break
            }
        }

        @objc func panned(_ r: UIPanGestureRecognizer) {
            guard r.state == .changed else { return }
            let t = r.translation(in: r.view)
            r.setTranslation(.zero, in: r.view)
            onPanDelta(CGSize(width: t.x, height: t.y))
        }

        @objc func twoFingerPanned(_ r: UIPanGestureRecognizer) {
            guard r.state == .changed else { return }
            let t = r.translation(in: r.view)
            r.setTranslation(.zero, in: r.view)
            onTwoFingerPanDelta(CGSize(width: t.x, height: t.y))
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

struct ImageColorPickerSheet: View {
    let images: [UIImage]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var imageIndex = 0
    @State private var tapLocation: CGPoint?
    @State private var pickedRGB: (r: Double, g: Double, b: Double)?
    @State private var editedColorName: String = ""
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showDuplicateAlert = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var colorNameFocused: Bool

    private var hasPickedColor: Bool { pickedRGB != nil }

    private var isAlreadyRegistered: Bool {
        let name = editedColorName.trimmingCharacters(in: .whitespaces)
        return clothingColors.contains(where: { $0.name == name })
            || CustomColorStore.load().contains(name)
    }

    private var cardBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.15, alpha: 1)
                : .white
        })
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { colorNameFocused = false; dismiss() }

            GeometryReader { geo in
                let w = max(0, geo.size.width - 40)
                let effectiveKeyboard = max(0, keyboardHeight - geo.safeAreaInsets.bottom)
                let baseH = w * 1.55
                let cardH = keyboardHeight > 0
                    ? min(baseH, geo.size.height - effectiveKeyboard - 16)
                    : baseH
                let cardY = keyboardHeight > 0
                    ? (geo.size.height - effectiveKeyboard) / 2
                    : geo.size.height / 2

                VStack(spacing: 0) {
                    headerBar
                    imagePickerArea
                    Divider()
                    controlsSection
                }
                .frame(width: w, height: cardH)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .contentShape(RoundedRectangle(cornerRadius: 24))
                .onTapGesture {}
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                .position(x: geo.size.width / 2, y: cardY)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
            if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = frame.height }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        .alert("이미 등록된 색상명입니다", isPresented: $showDuplicateAlert) {
            Button("불러오기") {
                onSelect(editedColorName.trimmingCharacters(in: .whitespaces))
                dismiss()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("등록되어있는 색상을 불러올까요?")
        }
    }

    private var headerBar: some View {
        ZStack {
            Text("색상 추출")
                .font(.system(size: 17, weight: .bold))
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.trailing, 20)
            }
        }
        .frame(height: 52)
    }

    private var imagePickerArea: some View {
        GeometryReader { geo in
            ZStack {
                Color(.secondarySystemGroupedBackground)

                Image(uiImage: images[imageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(scale, anchor: .center)
                    .offset(offset)

                if let loc = tapLocation, let (r, g, b) = pickedRGB {
                    ZStack {
                        Circle()
                            .fill(Color(red: r, green: g, blue: b))
                            .frame(width: 36, height: 36)
                        Circle()
                            .strokeBorder(.white, lineWidth: 2.5)
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                    }
                    .position(loc)
                    .allowsHitTesting(false)
                }

                ImageGestureOverlay(
                    onPinchDelta: { delta in
                        let newScale = max(1.0, min(5.0, scale * delta))
                        scale = newScale
                        if newScale <= 1.0 { offset = .zero }
                    },
                    onTwoFingerPan: { delta in
                        let maxX = geo.size.width  * (scale - 1) / 2
                        let maxY = geo.size.height * (scale - 1) / 2
                        offset = CGSize(
                            width:  max(-maxX, min(maxX,  offset.width  + delta.width)),
                            height: max(-maxY, min(maxY, offset.height + delta.height))
                        )
                    },
                    onSingleDrag: { loc in
                        colorNameFocused = false
                        tapLocation = loc
                        sampleColor(at: loc, in: geo.size)
                    }
                )
            }
            .clipped()
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 10) {
            if images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { i in
                            Image(uiImage: images[i])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(
                                            imageIndex == i ? Color.accentColor : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .onTapGesture {
                                    imageIndex = i
                                    tapLocation = nil
                                    pickedRGB = nil
                                    editedColorName = ""
                                    scale = 1.0
                                    offset = .zero
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            HStack(spacing: 12) {
                if let (r, g, b) = pickedRGB {
                    Circle()
                        .fill(Color(red: r, green: g, blue: b))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.5))
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "eyedropper")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        )
                }

                Group {
                    if hasPickedColor {
                        TextField("색상 이름 입력", text: $editedColorName)
                            .focused($colorNameFocused)
                            .submitLabel(.done)
                            .onSubmit { colorNameFocused = false }
                    } else {
                        Text("이미지를 탭하거나 드래그하세요")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)

                Spacer()

                Button("선택") {
                    let name = editedColorName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    if isAlreadyRegistered {
                        showDuplicateAlert = true
                    } else {
                        onSelect(name)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasPickedColor || editedColorName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 14)
    }

    private func sampleColor(at point: CGPoint, in containerSize: CGSize) {
        let image = images[imageIndex]
        let iw = image.size.width
        let ih = image.size.height
        let imageAspect = iw / ih
        let viewAspect  = containerSize.width / containerSize.height

        let imageRect: CGRect
        if imageAspect > viewAspect {
            let h = containerSize.width / imageAspect
            imageRect = CGRect(x: 0, y: (containerSize.height - h) / 2,
                               width: containerSize.width, height: h)
        } else {
            let w = containerSize.height * imageAspect
            imageRect = CGRect(x: (containerSize.width - w) / 2, y: 0,
                               width: w, height: containerSize.height)
        }

        // scale(중앙 기준) + offset 역변환
        let cx = containerSize.width / 2
        let cy = containerSize.height / 2
        let ox = cx + (point.x - offset.width  - cx) / scale
        let oy = cy + (point.y - offset.height - cy) / scale

        let nx = (ox - imageRect.minX) / imageRect.width
        let ny = (oy - imageRect.minY) / imageRect.height
        guard nx >= 0, nx <= 1, ny >= 0, ny <= 1 else { return }

        guard let (r, g, b) = ColorDetectionService.samplePixel(image: image, nx: nx, ny: ny) else { return }
        pickedRGB = (Double(r), Double(g), Double(b))
        editedColorName = ColorDetectionService.closestPaletteName(r: r, g: g, b: b)
    }
}

// MARK: - Info Components

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

struct SizeMeasurementRow: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("0", text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text("cm")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}

// MARK: - BG Remove Preview

enum PhotoBgOption: CaseIterable, Identifiable {
    case transparent, white, lightGrey, grey, darkGrey, black, beige, skyBlue

    var id: Self { self }

    var swiftUIColor: Color? {
        switch self {
        case .transparent: return nil
        case .white:       return .white
        case .lightGrey:   return Color(white: 0.92)
        case .grey:        return Color(white: 0.60)
        case .darkGrey:    return Color(white: 0.30)
        case .black:       return .black
        case .beige:       return Color(red: 0.96, green: 0.92, blue: 0.86)
        case .skyBlue:     return Color(red: 0.78, green: 0.88, blue: 0.96)
        }
    }

    var uiColor: UIColor? {
        switch self {
        case .transparent: return nil
        case .white:       return .white
        case .lightGrey:   return UIColor(white: 0.92, alpha: 1)
        case .grey:        return UIColor(white: 0.60, alpha: 1)
        case .darkGrey:    return UIColor(white: 0.30, alpha: 1)
        case .black:       return .black
        case .beige:       return UIColor(red: 0.96, green: 0.92, blue: 0.86, alpha: 1)
        case .skyBlue:     return UIColor(red: 0.78, green: 0.88, blue: 0.96, alpha: 1)
        }
    }
}

struct BgRemovePreviewSheet: View {
    let original: UIImage
    let removedBg: UIImage?
    let isLoading: Bool
    let error: String?
    let existingColor: String?
    var isEditMode: Bool = false
    var existingBg: PhotoBgOption = .transparent
    var cancelLabel: String = "다시 선택"
    let onAccept: (UIImage, String?, PhotoBgOption) -> Void
    let onCancel: () -> Void

    @State private var selectedBg: PhotoBgOption = .transparent
    @State private var colorSuggestions: [ColorSuggestion] = []
    @State private var colorAnalysisDone = false
    @State private var selectedSuggestion: String?
    @State private var paletteColor: String?
    @State private var showNewColorPicker = false
    @State private var showColorPalette = false

    @State private var showingColorPicker = false
    @State private var cpSampleNormalized: CGPoint?
    @State private var cpCroppedPreview: UIImage?
    @State private var cpPickedRGB: (r: Double, g: Double, b: Double)?
    @State private var cpColorName: String = ""
    @State private var cpScale: CGFloat = 1.0
    @State private var cpOffset: CGSize = .zero
    @FocusState private var cpNameFocused: Bool
    @State private var keyboardHeight: CGFloat = 0

    @State private var showCropView = false
    @State private var croppedImage: UIImage? = nil
    @State private var cropMinX: CGFloat = 0.05
    @State private var cropMinY: CGFloat = 0.05
    @State private var cropMaxX: CGFloat = 0.95
    @State private var cropMaxY: CGFloat = 0.95
    @State private var cropBodyStart: (CGFloat, CGFloat, CGFloat, CGFloat)?
    @State private var cropHandleStart: (CGFloat, CGFloat, CGFloat, CGFloat)?
    @State private var cropZoomScale: CGFloat = 1.0
    @State private var cropZoomScaleStart: CGFloat = 1.0
    @State private var cropPanOffset: CGSize = .zero

    private var displayImage: UIImage { croppedImage ?? removedBg ?? original }

    private var cardBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.15, alpha: 1)
                : .white
        })
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { if !isLoading { onCancel() } }

            GeometryReader { geo in
                let w = max(0, geo.size.width - 40)
                let h = max(0, w * 1.75)
                let effectiveKeyboard = max(0, keyboardHeight - geo.safeAreaInsets.bottom)
                let availableH = geo.size.height - effectiveKeyboard - 16
                let cardH: CGFloat = showingColorPicker && keyboardHeight > 0
                    ? max(250, min(h, availableH))
                    : h
                let cardY: CGFloat = showingColorPicker && keyboardHeight > 0
                    ? (geo.size.height - effectiveKeyboard) / 2
                    : geo.size.height / 2

                VStack(spacing: 0) {
                    if showingColorPicker {
                        colorPickerHeader
                            .zIndex(1)
                        colorPickerContent
                    } else {
                        headerBar
                        imageArea
                        if !isLoading { colorSuggestionRow }
                        if !isLoading { bgColorPicker }
                        if !isLoading { actionButtons }
                    }
                }
                .frame(width: w, height: cardH)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                .position(x: geo.size.width / 2, y: cardY)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
            if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = frame.height }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        .onAppear { selectedBg = existingBg }
        .task(id: isLoading) {
            guard !isLoading else { return }
            colorAnalysisDone = false
            let imageForDetection = removedBg ?? (isEditMode ? original : nil)
            guard let img = imageForDetection else {
                colorAnalysisDone = true
                return
            }
            paletteColor = existingColor?.isEmpty == false ? existingColor : nil
            let results = await withTaskGroup(of: [ColorSuggestion]?.self) { group in
                group.addTask { await ColorDetectionService.shared.detectColors(from: img) }
                group.addTask {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    return nil
                }
                let first = await group.next() ?? nil
                group.cancelAll()
                return first ?? []
            }
            colorSuggestions = results
            colorAnalysisDone = true
            if selectedSuggestion == nil {
                selectedSuggestion = paletteColor ?? results.first?.name
            }
        }
    }

    private var headerBar: some View {
        ZStack {
            Text(isEditMode ? "사진 수정" : "사진 등록")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(.label))
            if !isLoading {
                HStack {
                    Spacer()
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 10)
                }
            }
        }
        .frame(height: 55)
    }

    @ViewBuilder
    private var imageArea: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().scaleEffect(1.5)
                Text("배경 제거 중...")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 6) {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFit()
                    .background {
                        if let color = selectedBg.swiftUIColor {
                            Rectangle().fill(color)
                        } else if removedBg != nil {
                            CheckeredBackground()
                        }
                    }
                    .scaleEffect(showCropView ? cropZoomScale : 1.0, anchor: .center)
                    .offset(showCropView ? cropPanOffset : .zero)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    // 크롭 UI: 이미지 위에 직접 overlay
                    .overlay {
                        if showCropView {
                            GeometryReader { geo in
                                let imgFrame = cropZoomedFrame(base: cropImageFrame(in: geo.size), in: geo.size)
                                let cropRect  = cropViewRect(imageFrame: imgFrame)
                                ZStack {
                                    cropOverlay(imageFrame: imgFrame, cropRect: cropRect)
                                    Rectangle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                        .frame(width: cropRect.width, height: cropRect.height)
                                        .position(x: cropRect.midX, y: cropRect.midY)
                                    cropGrid(cropRect: cropRect)
                                    ForEach([0, 1, 2, 3], id: \.self) { i in
                                        cropHandle(corner: i, cropRect: cropRect, imageFrame: imgFrame, viewSize: geo.size)
                                    }
                                    // 맨 위 레이어: hitTest로 핸들 터치는 통과, 나머지는 직접 수신
                                    CropGestureView(
                                        onPinchDelta: { delta in
                                            cropZoomScale = max(1.0, min(4.0, cropZoomScale * delta))
                                        },
                                        onPanDelta: { delta in
                                            guard imgFrame.width > 0, imgFrame.height > 0 else { return }
                                            let dx = delta.width  / imgFrame.width
                                            let dy = delta.height / imgFrame.height
                                            let w = cropMaxX - cropMinX
                                            let h = cropMaxY - cropMinY
                                            let (visMinX, visMaxX, visMinY, visMaxY) = visibleCropBounds(imageFrame: imgFrame, viewSize: geo.size)
                                            cropMinX = min(max(cropMinX + dx, visMinX), visMaxX - w)
                                            cropMinY = min(max(cropMinY + dy, visMinY), visMaxY - h)
                                            cropMaxX = cropMinX + w
                                            cropMaxY = cropMinY + h
                                        },
                                        onTwoFingerPanDelta: { delta in
                                            let base = cropImageFrame(in: geo.size)
                                            let maxDx = base.width  * (cropZoomScale - 1) / 2
                                            let maxDy = base.height * (cropZoomScale - 1) / 2
                                            cropPanOffset.width  = max(-maxDx, min(maxDx, cropPanOffset.width  + delta.width))
                                            cropPanOffset.height = max(-maxDy, min(maxDy, cropPanOffset.height + delta.height))
                                        },
                                        handlePositions: [
                                            CGPoint(x: cropRect.minX, y: cropRect.minY),
                                            CGPoint(x: cropRect.maxX, y: cropRect.minY),
                                            CGPoint(x: cropRect.minX, y: cropRect.maxY),
                                            CGPoint(x: cropRect.maxX, y: cropRect.maxY)
                                        ]
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .clipped()
                        }
                    }
                    // 크롭 버튼 (크롭 모드 아닐 때만)
                    .overlay(alignment: .bottomTrailing) {
                        if !showCropView {
                            Button {
                                cropMinX = 0.05; cropMinY = 0.05
                                cropMaxX = 0.95; cropMaxY = 0.95
                                cropZoomScale = 1.0; cropZoomScaleStart = 1.0; cropPanOffset = .zero
                                showCropView = true
                            } label: {
                                Image(systemName: "crop")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(6)
                        }
                    }

                // 크롭 모드: 취소/적용 버튼
                if showCropView {
                    HStack(spacing: 10) {
                        Button { cropZoomScale = 1.0; cropZoomScaleStart = 1.0; cropPanOffset = .zero; showCropView = false } label: {
                            Text("취소")
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .contentShape(Capsule())
                        }
                        .foregroundStyle(Color(.label))
                        .background(Color.secondary.opacity(0.15), in: Capsule())
                        Button { applyCrop() } label: {
                            Text("적용")
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .contentShape(Capsule())
                        }
                        .foregroundStyle(.white)
                        .background(Color.accentColor, in: Capsule())
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 4)
                } else if let error, removedBg == nil {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: showCropView)
        }
    }

    private var colorSuggestionRow: some View {
        let isCustomPicked = cpCroppedPreview != nil
            && selectedSuggestion != nil
            && !colorSuggestions.contains(where: { $0.name == selectedSuggestion })
        let isPaletteSelected = !isCustomPicked
            && selectedSuggestion != nil
            && selectedSuggestion == paletteColor
            && !colorSuggestions.contains(where: { $0.name == selectedSuggestion })
        let paletteDisplayName = paletteColor

        return VStack(alignment: .leading, spacing: 6) {
            Text("옷 색상")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                // MARK: 새로 등록
                Button { showingColorPicker = true } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if isCustomPicked, let preview = cpCroppedPreview {
                                Image(uiImage: preview)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .foregroundStyle(Color.accentColor)
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                            if isCustomPicked {
                                Circle().strokeBorder(Color.accentColor, lineWidth: 2.5)
                            }
                        }
                        .frame(width: 32, height: 32)
                        Text(isCustomPicked ? (selectedSuggestion ?? "새로 등록") : "새로 등록")
                            .font(.system(size: 10))
                            .foregroundStyle(isCustomPicked ? Color(.label) : Color.accentColor)
                            .lineLimit(1)
                        Text(" ").font(.system(size: 9))
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 76)

                Divider().frame(height: 48)

                // MARK: 불러오기
                Button { showColorPalette = true } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            let allColors = clothingColors + CustomColorStore.loadEntries().map {
                                ClothingColor(name: $0.name, color: .secondary, isCustom: true, imagePath: $0.imagePath)
                            }
                            if let name = paletteDisplayName,
                               let item = allColors.first(where: { $0.name == name }) {
                                ColorCircle(item: item, size: 32, isSelected: isPaletteSelected)
                            } else {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .foregroundStyle(Color.accentColor)
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .frame(width: 32, height: 32)
                        Text(paletteDisplayName ?? "불러오기")
                            .font(.system(size: 10))
                            .foregroundStyle(paletteDisplayName != nil ? Color(.label) : Color.accentColor)
                            .lineLimit(1)
                        Text(" ").font(.system(size: 9))
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 76)

                Divider().frame(height: 48)

                // MARK: 추천
                HStack(spacing: 10) {
                    if colorSuggestions.isEmpty {
                        Text(colorAnalysisDone ? "색상 감지 불가" : "분석 중...")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(colorSuggestions.prefix(3), id: \.name) { suggestion in
                            Button { selectedSuggestion = suggestion.name } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        if let item = clothingColors.first(where: { $0.name == suggestion.name }) {
                                            Circle().fill(item.color)
                                        }
                                        Circle()
                                            .strokeBorder(
                                                selectedSuggestion == suggestion.name ? Color.accentColor : Color(.separator),
                                                lineWidth: selectedSuggestion == suggestion.name ? 2.5 : 0.5
                                            )
                                    }
                                    .frame(width: 32, height: 32)
                                    Text(suggestion.name)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color(.label))
                                        .lineLimit(1)
                                    Text("\(Int(suggestion.percentage * 100))%")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 80)
        .sheet(isPresented: $showColorPalette) {
            ColorPaletteSheet(selectedColor: Binding(
                get: { paletteColor ?? "" },
                set: { paletteColor = $0.isEmpty ? nil : $0 }
            )) { name in
                cpCroppedPreview = nil
                paletteColor = name
                selectedSuggestion = name
            }
        }
    }

    private var bgColorPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("배경 색상")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PhotoBgOption.allCases) { option in
                        Button {
                            selectedBg = option
                        } label: {
                            ZStack {
                                if let color = option.swiftUIColor {
                                    Circle().fill(color)
                                } else {
                                    CheckeredBackground().clipShape(Circle())
                                }
                                Circle()
                                    .strokeBorder(
                                        selectedBg == option ? Color.accentColor : Color(.separator),
                                        lineWidth: selectedBg == option ? 2.5 : 0.5
                                    )
                            }
                            .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(height: 62)
        .padding(.bottom, 6)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { onCancel() } label: {
                Text(isEditMode ? "취소" : cancelLabel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Capsule())
            }
            .foregroundStyle(Color(.label))
            .background(cardBackground)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color(.label), lineWidth: 1.5))

            Button { onAccept(compositeImage(), selectedSuggestion, selectedBg) } label: {
                Text(isEditMode ? "저장" : "사진 등록")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Capsule())
            }
            .foregroundStyle(cardBackground)
            .background(Color(.label))
            .clipShape(Capsule())
        }
        .font(.system(size: 15, weight: .medium))
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
    }

    private func compositeImage() -> UIImage {
        let base = displayImage
        guard (removedBg != nil || isEditMode), let bgColor = selectedBg.uiColor else { return base }
        let format = UIGraphicsImageRendererFormat()
        format.scale = base.scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: base.size, format: format).image { _ in
            bgColor.setFill()
            UIRectFill(CGRect(origin: .zero, size: base.size))
            base.draw(at: .zero)
        }
    }

    // MARK: Inline Crop
    private func cropImageFrame(in size: CGSize) -> CGRect {
        let imgAspect = displayImage.size.width / displayImage.size.height
        let cAspect   = size.width / size.height
        let displaySize: CGSize = imgAspect > cAspect
            ? CGSize(width: size.width,            height: size.width / imgAspect)
            : CGSize(width: size.height * imgAspect, height: size.height)
        return CGRect(
            x: (size.width  - displaySize.width)  / 2,
            y: (size.height - displaySize.height) / 2,
            width:  displaySize.width,
            height: displaySize.height
        )
    }

    private func cropZoomedFrame(base: CGRect, in size: CGSize) -> CGRect {
        let cx = size.width / 2
        let cy = size.height / 2
        return CGRect(
            x: cx + (base.minX - cx) * cropZoomScale + cropPanOffset.width,
            y: cy + (base.minY - cy) * cropZoomScale + cropPanOffset.height,
            width: base.width * cropZoomScale,
            height: base.height * cropZoomScale
        )
    }

    private func cropViewRect(imageFrame: CGRect) -> CGRect {
        CGRect(
            x: imageFrame.minX + cropMinX * imageFrame.width,
            y: imageFrame.minY + cropMinY * imageFrame.height,
            width:  (cropMaxX - cropMinX) * imageFrame.width,
            height: (cropMaxY - cropMinY) * imageFrame.height
        )
    }

    @ViewBuilder
    private func cropOverlay(imageFrame: CGRect, cropRect: CGRect) -> some View {
        let c = Color.black.opacity(0.55)
        let t = max(cropRect.minY - imageFrame.minY, 0)
        let b = max(imageFrame.maxY - cropRect.maxY, 0)
        let l = max(cropRect.minX - imageFrame.minX, 0)
        let r = max(imageFrame.maxX - cropRect.maxX, 0)
        Rectangle().fill(c).frame(width: imageFrame.width, height: t)
            .position(x: imageFrame.midX, y: imageFrame.minY + t / 2)
        Rectangle().fill(c).frame(width: imageFrame.width, height: b)
            .position(x: imageFrame.midX, y: cropRect.maxY + b / 2)
        Rectangle().fill(c).frame(width: l, height: cropRect.height)
            .position(x: imageFrame.minX + l / 2, y: cropRect.midY)
        Rectangle().fill(c).frame(width: r, height: cropRect.height)
            .position(x: cropRect.maxX + r / 2, y: cropRect.midY)
    }

    @ViewBuilder
    private func cropGrid(cropRect: CGRect) -> some View {
        let lc = Color.white.opacity(0.3)
        Rectangle().fill(lc).frame(width: 0.5, height: cropRect.height)
            .position(x: cropRect.minX + cropRect.width / 3, y: cropRect.midY)
        Rectangle().fill(lc).frame(width: 0.5, height: cropRect.height)
            .position(x: cropRect.minX + cropRect.width * 2 / 3, y: cropRect.midY)
        Rectangle().fill(lc).frame(width: cropRect.width, height: 0.5)
            .position(x: cropRect.midX, y: cropRect.minY + cropRect.height / 3)
        Rectangle().fill(lc).frame(width: cropRect.width, height: 0.5)
            .position(x: cropRect.midX, y: cropRect.minY + cropRect.height * 2 / 3)
    }

    private func visibleCropBounds(imageFrame: CGRect, viewSize: CGSize) -> (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        guard imageFrame.width > 0, imageFrame.height > 0 else { return (0, 1, 0, 1) }
        let minX = max(0, -imageFrame.minX / imageFrame.width)
        let maxX = min(1, (viewSize.width  - imageFrame.minX) / imageFrame.width)
        let minY = max(0, -imageFrame.minY / imageFrame.height)
        let maxY = min(1, (viewSize.height - imageFrame.minY) / imageFrame.height)
        return (minX, maxX, minY, maxY)
    }

    private func cropBodyGesture(imageFrame: CGRect, viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if cropBodyStart == nil {
                    cropBodyStart = (cropMinX, cropMinY, cropMaxX, cropMaxY)
                }
                guard let b = cropBodyStart, imageFrame.width > 0, imageFrame.height > 0 else { return }
                let dx = value.translation.width  / imageFrame.width
                let dy = value.translation.height / imageFrame.height
                let w = b.2 - b.0; let h = b.3 - b.1
                let (visMinX, visMaxX, visMinY, visMaxY) = visibleCropBounds(imageFrame: imageFrame, viewSize: viewSize)
                cropMinX = Swift.min(Swift.max(b.0 + dx, visMinX), visMaxX - w)
                cropMinY = Swift.min(Swift.max(b.1 + dy, visMinY), visMaxY - h)
                cropMaxX = cropMinX + w
                cropMaxY = cropMinY + h
            }
            .onEnded { _ in cropBodyStart = nil }
    }

    @ViewBuilder
    private func cropHandle(corner: Int, cropRect: CGRect, imageFrame: CGRect, viewSize: CGSize) -> some View {
        let pos: CGPoint = switch corner {
        case 0: CGPoint(x: cropRect.minX, y: cropRect.minY)
        case 1: CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case 2: CGPoint(x: cropRect.minX, y: cropRect.maxY)
        default: CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        }
        Circle()
            .fill(Color.white)
            .frame(width: 22, height: 22)
            .shadow(color: .black.opacity(0.3), radius: 2)
            .position(pos)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if cropHandleStart == nil {
                            cropHandleStart = (cropMinX, cropMinY, cropMaxX, cropMaxY)
                        }
                        guard let b = cropHandleStart, imageFrame.width > 0, imageFrame.height > 0 else { return }
                        let dx = value.translation.width  / imageFrame.width
                        let dy = value.translation.height / imageFrame.height
                        let minF: CGFloat = 0.05
                        let (visMinX, visMaxX, visMinY, visMaxY) = visibleCropBounds(imageFrame: imageFrame, viewSize: viewSize)
                        switch corner {
                        case 0:
                            cropMinX = Swift.min(Swift.max(b.0 + dx, visMinX), b.2 - minF)
                            cropMinY = Swift.min(Swift.max(b.1 + dy, visMinY), b.3 - minF)
                        case 1:
                            cropMaxX = Swift.min(Swift.max(b.2 + dx, b.0 + minF), visMaxX)
                            cropMinY = Swift.min(Swift.max(b.1 + dy, visMinY), b.3 - minF)
                        case 2:
                            cropMinX = Swift.min(Swift.max(b.0 + dx, visMinX), b.2 - minF)
                            cropMaxY = Swift.min(Swift.max(b.3 + dy, b.1 + minF), visMaxY)
                        default:
                            cropMaxX = Swift.min(Swift.max(b.2 + dx, b.0 + minF), visMaxX)
                            cropMaxY = Swift.min(Swift.max(b.3 + dy, b.1 + minF), visMaxY)
                        }
                    }
                    .onEnded { _ in cropHandleStart = nil }
            )
    }

    private func applyCrop() {
        let source = displayImage
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = source.scale

        // 1. orientation 정규화
        let oriented = UIGraphicsImageRenderer(size: source.size, format: format)
            .image { _ in source.draw(at: .zero) }

        // 2. 포인트 단위로 크롭 영역 계산
        let cropPt = CGRect(
            x: cropMinX * oriented.size.width,
            y: cropMinY * oriented.size.height,
            width:  (cropMaxX - cropMinX) * oriented.size.width,
            height: (cropMaxY - cropMinY) * oriented.size.height
        )
        guard cropPt.width > 0, cropPt.height > 0 else { showCropView = false; return }

        // 3. 포인트 기반 렌더러로 크롭 (픽셀 좌표 변환 불필요)
        croppedImage = UIGraphicsImageRenderer(size: cropPt.size, format: format)
            .image { _ in oriented.draw(at: CGPoint(x: -cropPt.origin.x, y: -cropPt.origin.y)) }
        cropZoomScale = 1.0; cropZoomScaleStart = 1.0; cropPanOffset = .zero
        showCropView = false
    }

    private var colorPickerHeader: some View {
        ZStack {
            Text("색상 추출")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(.label))
            HStack {
                Button {
                    showingColorPicker = false
                    cpSampleNormalized = nil
                    cpCroppedPreview = nil
                    cpPickedRGB = nil
                    cpColorName = ""
                    cpScale = 1.0
                    cpOffset = .zero
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(.label))
                        .frame(width: 32, height: 32)
                }
                .padding(.leading, 10)
                Spacer()
            }
        }
        .frame(height: 55)
        .contentShape(Rectangle())
        .onTapGesture { cpNameFocused = false }
    }

    private var colorPickerContent: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    Color(.secondarySystemBackground)
                    Image(uiImage: removedBg ?? original)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(cpScale, anchor: .center)
                        .offset(cpOffset)
                    if cpPickedRGB != nil,
                       let loc = cpDisplayLocation(in: geo.size) {
                        ZStack {
                            if let preview = cpCroppedPreview {
                                Image(uiImage: preview)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            }
                            Circle()
                                .strokeBorder(.white, lineWidth: 2.5)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.4), radius: 3)
                        }
                        .position(loc)
                        .allowsHitTesting(false)
                    }
                    ImageGestureOverlay(
                        onPinchDelta: { delta in
                            cpSampleNormalized = nil
                            let s = max(1.0, min(5.0, cpScale * delta))
                            cpScale = s
                            if s <= 1.0 { cpOffset = .zero }
                        },
                        onTwoFingerPan: { delta in
                            let maxX = geo.size.width  * (cpScale - 1) / 2
                            let maxY = geo.size.height * (cpScale - 1) / 2
                            cpOffset = CGSize(
                                width:  max(-maxX, min(maxX,  cpOffset.width  + delta.width)),
                                height: max(-maxY, min(maxY, cpOffset.height + delta.height))
                            )
                        },
                        onSingleDrag: { loc in
                            cpNameFocused = false
                            sampleColorForPicker(at: loc, in: geo.size)
                        }
                    )
                    .simultaneousGesture(TapGesture().onEnded {
                        cpNameFocused = false
                    })
                }
                .clipped()
            }

            Divider()

            HStack(spacing: 12) {
                if let preview = cpCroppedPreview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.5))
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "eyedropper").font(.system(size: 15)).foregroundStyle(.secondary))
                }
                Group {
                    if cpPickedRGB != nil {
                        TextField("색상 이름 입력", text: $cpColorName).focused($cpNameFocused)
                    } else {
                        Text("이미지를 탭하거나 드래그하세요").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                Spacer()
                Button("선택") {
                    let name = cpColorName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    if !clothingColors.contains(where: { $0.name == name }) {
                        let imagePath = cpCroppedPreview.flatMap {
                            try? ImageStorageService.shared.save($0, name: "custom_color_\(UUID().uuidString)")
                        }
                        CustomColorStore.add(name, imagePath: imagePath)
                    }
                    selectedSuggestion = name
                    showingColorPicker = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(cpPickedRGB == nil || cpColorName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(cardBackground)
            .contentShape(Rectangle())
            .onTapGesture { cpNameFocused = false }
        }
    }

    private func sampleColorForPicker(at point: CGPoint, in containerSize: CGSize) {
        let image = removedBg ?? original
        let imageAspect = image.size.width / image.size.height
        let viewAspect  = containerSize.width / containerSize.height
        let imageRect: CGRect
        if imageAspect > viewAspect {
            let h = containerSize.width / imageAspect
            imageRect = CGRect(x: 0, y: (containerSize.height - h) / 2, width: containerSize.width, height: h)
        } else {
            let w = containerSize.height * imageAspect
            imageRect = CGRect(x: (containerSize.width - w) / 2, y: 0, width: w, height: containerSize.height)
        }
        let cx = containerSize.width / 2
        let cy = containerSize.height / 2
        let ox = cx + (point.x - cpOffset.width  - cx) / cpScale
        let oy = cy + (point.y - cpOffset.height - cy) / cpScale
        let nx = (ox - imageRect.minX) / imageRect.width
        let ny = (oy - imageRect.minY) / imageRect.height
        guard nx >= 0, nx <= 1, ny >= 0, ny <= 1 else { return }
        guard let (r, g, b) = ColorDetectionService.samplePixel(image: image, nx: nx, ny: ny) else { return }
        cpSampleNormalized = CGPoint(x: nx, y: ny)
        cpCroppedPreview = cropPreview(image: image, nx: nx, ny: ny)
        cpPickedRGB = (Double(r), Double(g), Double(b))
        cpColorName = ColorDetectionService.closestPaletteName(r: r, g: g, b: b)
    }

    private func cropPreview(image: UIImage, nx: CGFloat, ny: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let pw = CGFloat(cgImage.width)
        let ph = CGFloat(cgImage.height)
        let cropFraction = 0.15 / max(1, cpScale)
        let cropW = pw * cropFraction
        let cropH = ph * cropFraction
        let cropX = max(0, min(pw - cropW, nx * pw - cropW / 2))
        let cropY = max(0, min(ph - cropH, ny * ph - cropH / 2))
        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        guard let cropped = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    private func cpDisplayLocation(in containerSize: CGSize) -> CGPoint? {
        guard let norm = cpSampleNormalized else { return nil }
        let image = removedBg ?? original
        let imageAspect = image.size.width / image.size.height
        let viewAspect  = containerSize.width / containerSize.height
        let imageRect: CGRect
        if imageAspect > viewAspect {
            let h = containerSize.width / imageAspect
            imageRect = CGRect(x: 0, y: (containerSize.height - h) / 2, width: containerSize.width, height: h)
        } else {
            let w = containerSize.height * imageAspect
            imageRect = CGRect(x: (containerSize.width - w) / 2, y: 0, width: w, height: containerSize.height)
        }
        let imageX = imageRect.minX + norm.x * imageRect.width
        let imageY = imageRect.minY + norm.y * imageRect.height
        let cx = containerSize.width / 2
        let cy = containerSize.height / 2
        return CGPoint(
            x: (imageX - cx) * cpScale + cx + cpOffset.width,
            y: (imageY - cy) * cpScale + cy + cpOffset.height
        )
    }
}

struct CheckeredBackground: View {
    var body: some View {
        Canvas { context, size in
            let tile: CGFloat = 12
            let cols = Int(ceil(size.width / tile))
            let rows = Int(ceil(size.height / tile))
            for row in 0..<rows {
                for col in 0..<cols {
                    let light = (row + col) % 2 == 0
                    context.fill(
                        Path(CGRect(x: CGFloat(col) * tile, y: CGFloat(row) * tile, width: tile, height: tile)),
                        with: .color(light ? Color(white: 0.85) : Color(white: 0.72))
                    )
                }
            }
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onSelect: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, @preconcurrency UINavigationControllerDelegate, @preconcurrency UIImagePickerControllerDelegate {
        private let onSelect: (UIImage) -> Void
        private let dismiss: DismissAction

        init(onSelect: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onSelect = onSelect
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onSelect(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Add Clothing

struct AddClothingView: View {
    @EnvironmentObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var category: ClothingCategory = .top
    @State private var subCategory: String = ClothingCategory.top.subCategories[0]
    @State private var material: ClothingMaterial = .cotton
    @State private var color = ""
    @State private var sizeLabel = ""
    @State private var showDetailSize = false
    @State private var sizeShoulder = ""
    @State private var sizeChest = ""
    @State private var sizeSleeve = ""
    @State private var sizeLength = ""
    @State private var purchasePrice = ""
    @State private var purchasePlace = ""

    @State private var selectedImages: [UIImage] = []
    @State private var imageBgOptions: [PhotoBgOption] = []
    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var galleryItems: [PhotosPickerItem] = []

    @State private var pendingImages: [UIImage] = []
    @State private var currentPendingImage: UIImage?
    @State private var removedBgImage: UIImage?
    @State private var isRemovingBg = false
    @State private var showBgPreview = false
    @State private var bgRemoveError: String?
    @State private var editingImageIndex: Int? = nil
    @State private var isFromCamera = false

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                Section("기본 정보") {
                    TextField("이름", text: $name)
                    TextField("브랜드", text: $brand)
                    Picker("카테고리", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .onChange(of: category) { _, newCategory in
                        subCategory = newCategory.subCategories[0]
                    }
                    Picker("세부 카테고리", selection: $subCategory) {
                        ForEach(category.subCategories, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    Picker("소재", selection: $material) {
                        ForEach(ClothingMaterial.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    ColorPickerRow(selectedColor: $color, images: selectedImages)
                }
                Section("사이즈") {
                    TextField("표기 사이즈 (예: M, 95, 100)", text: $sizeLabel)
                    Toggle(isOn: $showDetailSize) {
                        Text("상세 사이즈")
                            .font(.subheadline)
                    }
                    .onChange(of: showDetailSize) { _, checked in
                        if !checked {
                            sizeShoulder = ""
                            sizeChest = ""
                            sizeSleeve = ""
                            sizeLength = ""
                        }
                    }
                    if showDetailSize {
                        SizeMeasurementRow(label: "어깨단면", value: $sizeShoulder)
                        SizeMeasurementRow(label: "가슴단면", value: $sizeChest)
                        SizeMeasurementRow(label: "소매길이", value: $sizeSleeve)
                        SizeMeasurementRow(label: "총장",    value: $sizeLength)
                    }
                }
                Section("구매 정보 (선택)") {
                    HStack {
                        Text("구매가")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: formattedPriceBinding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 130)
                        Text("원")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    TextField("제품 링크", text: $purchasePlace)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("옷 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onChange(of: galleryItems) { _, newItems in
                Task { @MainActor in
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            pendingImages.append(image)
                        }
                    }
                    galleryItems = []
                    processNextBgIfIdle()
                }
            }
            .onChange(of: showCamera) { _, isShowing in
                if !isShowing {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        processNextBgIfIdle()
                    }
                }
            }
            .confirmationDialog("사진 추가 방법 선택", isPresented: $showSourcePicker) {
                Button("카메라로 촬영") { isFromCamera = true; showCamera = true }
                Button("갤러리에서 선택") { isFromCamera = false; showGallery = true }
                Button("취소", role: .cancel) {}
            }
            .photosPicker(isPresented: $showGallery, selection: $galleryItems, maxSelectionCount: 5 - selectedImages.count, matching: .images)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView { image in
                    pendingImages.append(image)
                }
            }
            .fullScreenCover(isPresented: $showBgPreview) {
                NavigationStack {
                    if let current = currentPendingImage {
                        BgRemovePreviewSheet(
                            original: current,
                            removedBg: removedBgImage,
                            isLoading: isRemovingBg,
                            error: bgRemoveError,
                            existingColor: color.isEmpty ? nil : color,
                            cancelLabel: isFromCamera ? "다시 촬영" : "다시 선택"
                        ) { finalImage, detectedColor, bg in
                            selectedImages.append(finalImage)
                            imageBgOptions.append(bg)
                            if let c = detectedColor { color = c }
                            finishBgPreview()
                        } onCancel: {
                            let fromCamera = isFromCamera
                            pendingImages = []
                            finishBgPreview()
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(450))
                                if fromCamera { showCamera = true } else { showGallery = true }
                            }
                        }
                        .toolbar(.hidden, for: .navigationBar)
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { editingImageIndex != nil },
                set: { if !$0 { editingImageIndex = nil } }
            )) {
                if let idx = editingImageIndex, idx < selectedImages.count {
                    NavigationStack {
                        BgRemovePreviewSheet(
                            original: selectedImages[idx],
                            removedBg: nil,
                            isLoading: false,
                            error: nil,
                            existingColor: color.isEmpty ? nil : color,
                            isEditMode: true,
                            existingBg: idx < imageBgOptions.count ? imageBgOptions[idx] : .transparent
                        ) { finalImage, detectedColor, bg in
                            selectedImages[idx] = finalImage
                            if idx < imageBgOptions.count { imageBgOptions[idx] = bg } else { imageBgOptions.append(bg) }
                            if let c = detectedColor, !c.isEmpty { color = c }
                            editingImageIndex = nil
                        } onCancel: {
                            editingImageIndex = nil
                        }
                        .toolbar(.hidden, for: .navigationBar)
                    }
                }
            }
        }
    }

    private func processNextBgIfIdle() {
        guard !showBgPreview, !pendingImages.isEmpty else { return }
        let image = pendingImages.removeFirst()
        currentPendingImage = image
        isRemovingBg = true
        bgRemoveError = nil
        removedBgImage = nil
        showBgPreview = true
        Task { @MainActor in
            do { removedBgImage = try await RemoveBgService.shared.removeBackground(from: image) }
            catch { bgRemoveError = error.localizedDescription }
            isRemovingBg = false
        }
    }

    private func finishBgPreview() {
        showBgPreview = false
        currentPendingImage = nil
        removedBgImage = nil
        bgRemoveError = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            processNextBgIfIdle()
        }
    }

    private var formattedPriceBinding: Binding<String> {
        Binding(
            get: {
                guard !purchasePrice.isEmpty, let value = Int(purchasePrice) else { return purchasePrice }
                return value.formatted()
            },
            set: { newValue in
                purchasePrice = newValue.filter { $0.isNumber }
            }
        )
    }

    private var addPhotoButton: some View {
        let count = selectedImages.count
        return Button {
            showSourcePicker = true
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 88, height: 88)
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("\(count)/5")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
        }
        .buttonStyle(.plain)
    }

    private var photoSection: some View {
        Section("사진") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedImages.indices, id: \.self) { idx in
                        Image(uiImage: selectedImages[idx])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                            .onTapGesture { editingImageIndex = idx }
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    selectedImages.remove(at: idx)
                                    if idx < imageBgOptions.count { imageBgOptions.remove(at: idx) }
                                    if selectedImages.isEmpty { color = "" }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.black.opacity(0.6))
                                        .font(.title3)
                                        .padding(4)
                                }
                            }
                    }
                    if selectedImages.count < 5 {
                        addPhotoButton
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func save() {
        Task { @MainActor in
            let clothingID = UUID()
            var imagePaths: [String] = []
            for (idx, image) in selectedImages.enumerated() {
                let name = "\(clothingID.uuidString)_\(idx)"
                if let path = try? ImageStorageService.shared.save(image, name: name) {
                    imagePaths.append(path)
                }
            }
            let clothing = ClothingEntity(
                id: clothingID,
                name: name,
                brand: brand,
                category: category,
                subCategory: subCategory,
                material: material,
                color: color,
                size: ClothingSize(
                    label: sizeLabel,
                    shoulder: Double(sizeShoulder),
                    chest: Double(sizeChest),
                    sleeve: Double(sizeSleeve),
                    length: Double(sizeLength)
                ),
                alterationHistory: [],
                rating: 0,
                review: "",
                wearCount: 0,
                purchaseDate: Date(),
                purchasePrice: Double(purchasePrice),
                purchasePlace: purchasePlace,
                imageURLs: imagePaths,
                tags: [],
                isActive: true
            )
            await viewModel.addClothing(clothing)
            dismiss()
        }
    }
}

// MARK: - Edit Clothing

struct EditClothingView: View {
    @EnvironmentObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) private var dismiss

    let original: ClothingEntity

    @State private var name: String
    @State private var brand: String
    @State private var category: ClothingCategory
    @State private var subCategory: String
    @State private var material: ClothingMaterial
    @State private var color: String
    @State private var sizeLabel: String
    @State private var showDetailSize: Bool
    @State private var sizeShoulder: String
    @State private var sizeChest: String
    @State private var sizeSleeve: String
    @State private var sizeLength: String
    @State private var purchasePrice: String
    @State private var purchasePlace: String

    @State private var selectedImages: [UIImage] = []
    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var galleryItems: [PhotosPickerItem] = []

    @State private var pendingImages: [UIImage] = []
    @State private var currentPendingImage: UIImage?
    @State private var removedBgImage: UIImage?
    @State private var isRemovingBg = false
    @State private var showBgPreview = false
    @State private var bgRemoveError: String?

    init(clothing: ClothingEntity) {
        self.original = clothing
        _name          = State(initialValue: clothing.name)
        _brand         = State(initialValue: clothing.brand)
        _category      = State(initialValue: clothing.category)
        _subCategory   = State(initialValue: clothing.subCategory.isEmpty ? clothing.category.subCategories[0] : clothing.subCategory)
        _material      = State(initialValue: clothing.material)
        _color         = State(initialValue: clothing.color)
        _sizeLabel     = State(initialValue: clothing.size.label)
        let hasDetail  = clothing.size.shoulder != nil || clothing.size.chest != nil
                      || clothing.size.sleeve != nil   || clothing.size.length != nil
        _showDetailSize = State(initialValue: hasDetail)
        _sizeShoulder  = State(initialValue: clothing.size.shoulder.map { String($0) } ?? "")
        _sizeChest     = State(initialValue: clothing.size.chest.map    { String($0) } ?? "")
        _sizeSleeve    = State(initialValue: clothing.size.sleeve.map   { String($0) } ?? "")
        _sizeLength    = State(initialValue: clothing.size.length.map   { String($0) } ?? "")
        _purchasePrice = State(initialValue: clothing.purchasePrice.map { String(Int($0)) } ?? "")
        _purchasePlace = State(initialValue: clothing.purchasePlace)
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                Section("기본 정보") {
                    TextField("이름", text: $name)
                    TextField("브랜드", text: $brand)
                    Picker("카테고리", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .onChange(of: category) { _, newCategory in
                        subCategory = newCategory.subCategories[0]
                    }
                    Picker("세부 카테고리", selection: $subCategory) {
                        ForEach(category.subCategories, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    Picker("소재", selection: $material) {
                        ForEach(ClothingMaterial.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    ColorPickerRow(selectedColor: $color, images: selectedImages)
                }
                Section("사이즈") {
                    TextField("표기 사이즈 (예: M, 95, 100)", text: $sizeLabel)
                    Toggle(isOn: $showDetailSize) {
                        Text("상세 사이즈").font(.subheadline)
                    }
                    .onChange(of: showDetailSize) { _, checked in
                        if !checked {
                            sizeShoulder = ""; sizeChest = ""; sizeSleeve = ""; sizeLength = ""
                        }
                    }
                    if showDetailSize {
                        SizeMeasurementRow(label: "어깨단면", value: $sizeShoulder)
                        SizeMeasurementRow(label: "가슴단면", value: $sizeChest)
                        SizeMeasurementRow(label: "소매길이", value: $sizeSleeve)
                        SizeMeasurementRow(label: "총장",    value: $sizeLength)
                    }
                }
                Section("구매 정보 (선택)") {
                    HStack {
                        Text("구매가").foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: formattedPriceBinding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 130)
                        Text("원").foregroundStyle(.secondary).font(.subheadline)
                    }
                    TextField("제품 링크", text: $purchasePlace)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("옷 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onChange(of: galleryItems) { _, newItems in
                Task { @MainActor in
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            pendingImages.append(image)
                        }
                    }
                    galleryItems = []
                    processNextBgIfIdle()
                }
            }
            .onChange(of: showCamera) { _, isShowing in
                if !isShowing {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        processNextBgIfIdle()
                    }
                }
            }
            .task {
                selectedImages = original.imageURLs.compactMap {
                    ImageStorageService.shared.load(path: $0)
                }
            }
            .confirmationDialog("사진 추가 방법 선택", isPresented: $showSourcePicker) {
                Button("카메라로 촬영") { showCamera = true }
                Button("갤러리에서 선택") { showGallery = true }
                Button("취소", role: .cancel) {}
            }
            .photosPicker(isPresented: $showGallery, selection: $galleryItems, maxSelectionCount: 5 - selectedImages.count, matching: .images)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView { image in
                    pendingImages.append(image)
                }
            }
            .fullScreenCover(isPresented: $showBgPreview) {
                NavigationStack {
                    if let current = currentPendingImage {
                        BgRemovePreviewSheet(
                            original: current,
                            removedBg: removedBgImage,
                            isLoading: isRemovingBg,
                            error: bgRemoveError,
                            existingColor: color.isEmpty ? nil : color
                        ) { finalImage, detectedColor, _ in
                            selectedImages.append(finalImage)
                            if let c = detectedColor { color = c }
                            finishBgPreview()
                        } onCancel: {
                            pendingImages = []
                            finishBgPreview()
                        }
                        .toolbar(.hidden, for: .navigationBar)
                    }
                }
            }
        }
    }

    private func processNextBgIfIdle() {
        guard !showBgPreview, !pendingImages.isEmpty else { return }
        let image = pendingImages.removeFirst()
        currentPendingImage = image
        isRemovingBg = true
        bgRemoveError = nil
        removedBgImage = nil
        showBgPreview = true
        Task { @MainActor in
            do { removedBgImage = try await RemoveBgService.shared.removeBackground(from: image) }
            catch { bgRemoveError = error.localizedDescription }
            isRemovingBg = false
        }
    }

    private func finishBgPreview() {
        showBgPreview = false
        currentPendingImage = nil
        removedBgImage = nil
        bgRemoveError = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            processNextBgIfIdle()
        }
    }

    private var formattedPriceBinding: Binding<String> {
        Binding(
            get: {
                guard !purchasePrice.isEmpty, let value = Int(purchasePrice) else { return purchasePrice }
                return value.formatted()
            },
            set: { newValue in
                purchasePrice = newValue.filter { $0.isNumber }
            }
        )
    }

    private var addPhotoButton: some View {
        let count = selectedImages.count
        return Button {
            showSourcePicker = true
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 88, height: 88)
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill").font(.title2)
                        Text("\(count)/5").font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
        }
        .buttonStyle(.plain)
    }

    private var photoSection: some View {
        Section("사진") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedImages.indices, id: \.self) { idx in
                        Image(uiImage: selectedImages[idx])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    selectedImages.remove(at: idx)
                                    if selectedImages.isEmpty { color = "" }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.black.opacity(0.6))
                                        .font(.title3)
                                        .padding(4)
                                }
                            }
                    }
                    if selectedImages.count < 5 { addPhotoButton }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func save() {
        Task { @MainActor in
            // 기존 이미지 파일 삭제
            for path in original.imageURLs {
                ImageStorageService.shared.delete(path: path)
            }
            // 현재 이미지 저장
            var imagePaths: [String] = []
            for (idx, image) in selectedImages.enumerated() {
                let fileName = "\(original.id.uuidString)_\(idx)"
                if let path = try? ImageStorageService.shared.save(image, name: fileName) {
                    imagePaths.append(path)
                }
            }
            let updated = ClothingEntity(
                id: original.id,
                name: name,
                brand: brand,
                category: category,
                subCategory: subCategory,
                material: material,
                color: color,
                size: ClothingSize(
                    label: sizeLabel,
                    shoulder: Double(sizeShoulder),
                    chest: Double(sizeChest),
                    sleeve: Double(sizeSleeve),
                    length: Double(sizeLength)
                ),
                alterationHistory: original.alterationHistory,
                rating: original.rating,
                review: original.review,
                wearCount: original.wearCount,
                purchaseDate: original.purchaseDate,
                purchasePrice: Double(purchasePrice),
                purchasePlace: purchasePlace,
                imageURLs: imagePaths,
                tags: original.tags,
                isActive: original.isActive
            )
            await viewModel.updateClothing(updated)
            dismiss()
        }
    }
}

// MARK: - Image Crop View

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var cropMinX: CGFloat = 0.05
    @State private var cropMinY: CGFloat = 0.05
    @State private var cropMaxX: CGFloat = 0.95
    @State private var cropMaxY: CGFloat = 0.95

    @State private var bodyDragInitial: CropBounds?
    @State private var handleDragInitial: CropBounds?

    private let minCropFraction: CGFloat = 0.05
    private let handleSize: CGFloat = 22

    private struct CropBounds {
        var minX, minY, maxX, maxY: CGFloat
    }

    private enum CropCorner: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let imgFrame = imageDisplayFrame(in: geo.size)
                let cropView  = cropRectInView(imageFrame: imgFrame)

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imgFrame.width, height: imgFrame.height)
                        .position(x: imgFrame.midX, y: imgFrame.midY)

                    overlayRects(imageFrame: imgFrame, cropRect: cropView)

                    Rectangle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: cropView.width, height: cropView.height)
                        .position(x: cropView.midX, y: cropView.midY)

                    gridLines(cropRect: cropView)

                    Color.clear
                        .frame(
                            width: max(cropView.width - handleSize * 2, 0),
                            height: max(cropView.height - handleSize * 2, 0)
                        )
                        .position(x: cropView.midX, y: cropView.midY)
                        .gesture(bodyMoveGesture(imageFrame: imgFrame))

                    ForEach(CropCorner.allCases, id: \.self) { corner in
                        cornerHandle(corner: corner, cropRect: cropView, imageFrame: imgFrame)
                    }
                }
            }

            VStack {
                Spacer()
                HStack {
                    Button("취소") { onCancel() }
                        .foregroundStyle(.white)
                        .font(.body)
                    Spacer()
                    Button("적용") { performCrop() }
                        .foregroundStyle(Color.accentColor)
                        .font(.body.bold())
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.7))
            }
        }
    }

    // MARK: Geometry

    private func imageDisplayFrame(in size: CGSize) -> CGRect {
        let imgAspect = image.size.width / image.size.height
        let containerAspect = size.width / size.height
        let displaySize: CGSize
        if imgAspect > containerAspect {
            displaySize = CGSize(width: size.width, height: size.width / imgAspect)
        } else {
            displaySize = CGSize(width: size.height * imgAspect, height: size.height)
        }
        return CGRect(
            x: (size.width  - displaySize.width)  / 2,
            y: (size.height - displaySize.height) / 2,
            width:  displaySize.width,
            height: displaySize.height
        )
    }

    private func cropRectInView(imageFrame: CGRect) -> CGRect {
        CGRect(
            x: imageFrame.minX + cropMinX * imageFrame.width,
            y: imageFrame.minY + cropMinY * imageFrame.height,
            width:  (cropMaxX - cropMinX) * imageFrame.width,
            height: (cropMaxY - cropMinY) * imageFrame.height
        )
    }

    // MARK: Overlay

    @ViewBuilder
    private func overlayRects(imageFrame: CGRect, cropRect: CGRect) -> some View {
        let c = Color.black.opacity(0.55)
        let top    = max(cropRect.minY - imageFrame.minY, 0)
        let bottom = max(imageFrame.maxY - cropRect.maxY, 0)
        let left   = max(cropRect.minX - imageFrame.minX, 0)
        let right  = max(imageFrame.maxX - cropRect.maxX, 0)

        Rectangle().fill(c)
            .frame(width: imageFrame.width, height: top)
            .position(x: imageFrame.midX, y: imageFrame.minY + top / 2)
        Rectangle().fill(c)
            .frame(width: imageFrame.width, height: bottom)
            .position(x: imageFrame.midX, y: cropRect.maxY + bottom / 2)
        Rectangle().fill(c)
            .frame(width: left, height: cropRect.height)
            .position(x: imageFrame.minX + left / 2, y: cropRect.midY)
        Rectangle().fill(c)
            .frame(width: right, height: cropRect.height)
            .position(x: cropRect.maxX + right / 2, y: cropRect.midY)
    }

    @ViewBuilder
    private func gridLines(cropRect: CGRect) -> some View {
        let lc = Color.white.opacity(0.3)
        Rectangle().fill(lc)
            .frame(width: 0.5, height: cropRect.height)
            .position(x: cropRect.minX + cropRect.width / 3, y: cropRect.midY)
        Rectangle().fill(lc)
            .frame(width: 0.5, height: cropRect.height)
            .position(x: cropRect.minX + cropRect.width * 2 / 3, y: cropRect.midY)
        Rectangle().fill(lc)
            .frame(width: cropRect.width, height: 0.5)
            .position(x: cropRect.midX, y: cropRect.minY + cropRect.height / 3)
        Rectangle().fill(lc)
            .frame(width: cropRect.width, height: 0.5)
            .position(x: cropRect.midX, y: cropRect.minY + cropRect.height * 2 / 3)
    }

    // MARK: Gestures

    private func bodyMoveGesture(imageFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if bodyDragInitial == nil {
                    bodyDragInitial = CropBounds(minX: cropMinX, minY: cropMinY, maxX: cropMaxX, maxY: cropMaxY)
                }
                guard let b = bodyDragInitial, imageFrame.width > 0, imageFrame.height > 0 else { return }
                let dx = value.translation.width  / imageFrame.width
                let dy = value.translation.height / imageFrame.height
                let w = b.maxX - b.minX
                let h = b.maxY - b.minY
                cropMinX = clamp(b.minX + dx, lo: 0, hi: 1 - w)
                cropMinY = clamp(b.minY + dy, lo: 0, hi: 1 - h)
                cropMaxX = cropMinX + w
                cropMaxY = cropMinY + h
            }
            .onEnded { _ in bodyDragInitial = nil }
    }

    @ViewBuilder
    private func cornerHandle(corner: CropCorner, cropRect: CGRect, imageFrame: CGRect) -> some View {
        let pos: CGPoint = switch corner {
        case .topLeft:     CGPoint(x: cropRect.minX, y: cropRect.minY)
        case .topRight:    CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeft:  CGPoint(x: cropRect.minX, y: cropRect.maxY)
        case .bottomRight: CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        }

        Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .shadow(color: .black.opacity(0.3), radius: 2)
            .position(pos)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if handleDragInitial == nil {
                            handleDragInitial = CropBounds(minX: cropMinX, minY: cropMinY, maxX: cropMaxX, maxY: cropMaxY)
                        }
                        guard let b = handleDragInitial, imageFrame.width > 0, imageFrame.height > 0 else { return }
                        let dx = value.translation.width  / imageFrame.width
                        let dy = value.translation.height / imageFrame.height
                        switch corner {
                        case .topLeft:
                            cropMinX = clamp(b.minX + dx, lo: 0, hi: b.maxX - minCropFraction)
                            cropMinY = clamp(b.minY + dy, lo: 0, hi: b.maxY - minCropFraction)
                        case .topRight:
                            cropMaxX = clamp(b.maxX + dx, lo: b.minX + minCropFraction, hi: 1)
                            cropMinY = clamp(b.minY + dy, lo: 0, hi: b.maxY - minCropFraction)
                        case .bottomLeft:
                            cropMinX = clamp(b.minX + dx, lo: 0, hi: b.maxX - minCropFraction)
                            cropMaxY = clamp(b.maxY + dy, lo: b.minY + minCropFraction, hi: 1)
                        case .bottomRight:
                            cropMaxX = clamp(b.maxX + dx, lo: b.minX + minCropFraction, hi: 1)
                            cropMaxY = clamp(b.maxY + dy, lo: b.minY + minCropFraction, hi: 1)
                        }
                    }
                    .onEnded { _ in handleDragInitial = nil }
            )
    }

    // MARK: Crop

    private func performCrop() {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = image.scale
        let oriented = UIGraphicsImageRenderer(size: image.size, format: format)
            .image { _ in image.draw(at: .zero) }
        let cropPt = CGRect(
            x: cropMinX * oriented.size.width,
            y: cropMinY * oriented.size.height,
            width:  (cropMaxX - cropMinX) * oriented.size.width,
            height: (cropMaxY - cropMinY) * oriented.size.height
        )
        guard cropPt.width > 0, cropPt.height > 0 else { onCancel(); return }
        let cropped = UIGraphicsImageRenderer(size: cropPt.size, format: format)
            .image { _ in oriented.draw(at: CGPoint(x: -cropPt.origin.x, y: -cropPt.origin.y)) }
        onCrop(cropped)
    }

    private func clamp(_ value: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, lo), hi)
    }
}
