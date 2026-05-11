import SwiftUI

struct ClosetView: View {
    @EnvironmentObject var viewModel: ClosetViewModel
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterView(selectedCategory: $viewModel.selectedCategory)

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

struct ClothingGridView: View {
    let items: [ClothingEntity]
    let columns = [GridItem(.adaptive(minimum: 160))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    NavigationLink(destination: ClothingDetailView(clothing: item)) {
                        ClothingCard(clothing: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct ClothingCard: View {
    let clothing: ClothingEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.15))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "tshirt")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }

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

struct ClothingDetailView: View {
    let clothing: ClothingEntity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .overlay {
                        Image(systemName: "tshirt")
                            .font(.system(size: 80))
                            .foregroundStyle(.secondary)
                    }

                Group {
                    InfoSection(title: "기본 정보") {
                        InfoRow(label: "브랜드", value: clothing.brand)
                        InfoRow(label: "카테고리", value: clothing.category.rawValue)
                        InfoRow(label: "소재", value: clothing.material.rawValue)
                        InfoRow(label: "색상", value: clothing.color)
                        InfoRow(label: "사이즈", value: clothing.size.label)
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
                            Text(clothing.review)
                                .font(.body)
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

struct AddClothingView: View {
    @EnvironmentObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var category: ClothingCategory = .top
    @State private var material: ClothingMaterial = .cotton
    @State private var color = ""
    @State private var sizeLabel = ""
    @State private var purchasePrice = ""
    @State private var purchasePlace = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름", text: $name)
                    TextField("브랜드", text: $brand)
                    Picker("카테고리", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    Picker("소재", selection: $material) {
                        ForEach(ClothingMaterial.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    TextField("색상", text: $color)
                    TextField("사이즈", text: $sizeLabel)
                }
                Section("구매 정보 (선택)") {
                    TextField("구매가", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("구매처", text: $purchasePlace)
                }
            }
            .navigationTitle("옷 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            let clothing = ClothingEntity(
                                id: UUID(),
                                name: name,
                                brand: brand,
                                category: category,
                                material: material,
                                color: color,
                                size: ClothingSize(label: sizeLabel),
                                alterationHistory: [],
                                rating: 0,
                                review: "",
                                wearCount: 0,
                                purchaseDate: Date(),
                                purchasePrice: Double(purchasePrice),
                                purchasePlace: purchasePlace,
                                imageURLs: [],
                                tags: [],
                                isActive: true
                            )
                            await viewModel.addClothing(clothing)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
