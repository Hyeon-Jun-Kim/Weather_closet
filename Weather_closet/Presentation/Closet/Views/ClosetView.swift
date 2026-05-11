import SwiftUI
import PhotosUI

struct ClosetView: View {
    @EnvironmentObject var viewModel: ClosetViewModel
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                } else {
                    ClothingGridView(items: viewModel.filteredList)
                        .environmentObject(viewModel)
                }
            }
            .navigationTitle("옷장")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await viewModel.loadClothing() }
            .sheet(isPresented: $showAddSheet) {
                AddClothingView()
                    .environmentObject(viewModel)
            }
        }
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
                    if let price = clothing.purchasePrice {
                        InfoSection(title: "구매 정보") {
                            InfoRow(label: "구매가", value: "\(Int(price).formatted())원")
                            InfoRow(label: "구매처", value: clothing.purchasePlace)
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
}

private let clothingColors: [ClothingColor] = [
    .init(name: "블랙",    color: Color(white: 0.08)),
    .init(name: "화이트",   color: Color(white: 0.95)),
    .init(name: "그레이",   color: Color(white: 0.55)),
    .init(name: "네이비",   color: Color(red: 0.05, green: 0.10, blue: 0.30)),
    .init(name: "베이지",   color: Color(red: 0.93, green: 0.86, blue: 0.73)),
    .init(name: "브라운",   color: Color(red: 0.45, green: 0.25, blue: 0.12)),
    .init(name: "버건디",   color: Color(red: 0.50, green: 0.00, blue: 0.13)),
    .init(name: "레드",    color: .red),
    .init(name: "핑크",    color: Color(red: 1.0, green: 0.60, blue: 0.75)),
    .init(name: "오렌지",   color: .orange),
    .init(name: "옐로우",   color: .yellow),
    .init(name: "카키",    color: Color(red: 0.46, green: 0.47, blue: 0.26)),
    .init(name: "그린",    color: Color(red: 0.18, green: 0.55, blue: 0.25)),
    .init(name: "민트",    color: Color(red: 0.55, green: 0.88, blue: 0.80)),
    .init(name: "블루",    color: .blue),
    .init(name: "스카이블루", color: Color(red: 0.53, green: 0.81, blue: 0.98)),
    .init(name: "퍼플",    color: .purple),
    .init(name: "멀티",    color: .clear),
]

struct ColorPickerRow: View {
    @Binding var selectedColor: String
    @State private var searchText = ""
    @State private var showPalette = false

    private var suggestions: [ClothingColor] {
        guard !searchText.isEmpty else { return [] }
        return clothingColors.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let matched = clothingColors.first(where: { $0.name == selectedColor }) {
                    ColorCircle(item: matched, size: 24, isSelected: false)
                }
                TextField("색상 직접 입력", text: $searchText)
                    .onChange(of: searchText) { _, text in
                        if let exact = clothingColors.first(where: { $0.name == text }) {
                            selectedColor = exact.name
                        }
                    }
                Button {
                    showPalette = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }

            if !suggestions.isEmpty {
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
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showPalette) {
            ColorPaletteSheet(selectedColor: $selectedColor) { name in
                searchText = name
            }
        }
    }
}

struct ColorCircle: View {
    let item: ClothingColor
    let size: CGFloat
    let isSelected: Bool

    private var isLight: Bool {
        ["화이트", "옐로우", "민트", "스카이블루", "베이지"].contains(item.name)
    }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
            Group {
                if item.name == "멀티" {
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
    }
}

struct ColorPaletteSheet: View {
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(clothingColors) { item in
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
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
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

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

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
                    ColorPickerRow(selectedColor: $color)
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
                    TextField("구매처", text: $purchasePlace)
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
            .onChange(of: selectedItems) { _, newItems in
                Task { @MainActor in
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                    selectedItems = []
                }
            }
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
        let remaining = 5 - count
        return PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: remaining,
            matching: .images
        ) {
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

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

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
                    ColorPickerRow(selectedColor: $color)
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
                    TextField("구매처", text: $purchasePlace)
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
            .onChange(of: selectedItems) { _, newItems in
                Task { @MainActor in
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                    selectedItems = []
                }
            }
            .task {
                selectedImages = original.imageURLs.compactMap {
                    ImageStorageService.shared.load(path: $0)
                }
            }
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
        let remaining = 5 - count
        return PhotosPicker(selection: $selectedItems, maxSelectionCount: remaining, matching: .images) {
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
