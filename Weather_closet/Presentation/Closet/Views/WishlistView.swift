import SwiftUI
import PhotosUI

// MARK: - WishlistView

struct WishlistView: View {
    @EnvironmentObject var viewModel: WishlistViewModel
    @Binding var showAddSheet: Bool
    @State private var itemToEdit: WishlistItemEntity?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "위시리스트가 비어있습니다",
                    systemImage: "heart",
                    description: Text("+ 버튼으로 아이템을 추가해보세요.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        WishlistRowView(item: item)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .contextMenu {
                                Button { itemToEdit = item } label: {
                                    Label("수정", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(id: item.id) }
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                    .onMove { source, destination in
                        Task { await viewModel.move(from: source, to: destination) }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            Task { await viewModel.load() }
        }) {
            AddWishlistItemView()
                .environmentObject(viewModel)
        }
        .sheet(item: $itemToEdit, onDismiss: {
            Task { await viewModel.load() }
        }) { item in
            AddWishlistItemView(editing: item)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Row

struct WishlistRowView: View {
    let item: WishlistItemEntity

    var body: some View {
        if let comp = item.comparison {
            WishlistComparisonRowView(item: item, comparison: comp)
        } else {
            WishlistSingleRowView(item: item)
        }
    }
}

struct WishlistSingleRowView: View {
    let item: WishlistItemEntity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WishlistThumbnail(imageURLs: item.imageURLs, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                if !item.name.isEmpty {
                    Text(item.name)
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(1)
                }
                WishlistInfoGrid(brand: item.brand, categoryRaw: item.categoryRaw, price: item.price,
                                 goodPoint: item.goodPoint, badPoint: item.badPoint)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct WishlistComparisonRowView: View {
    let item: WishlistItemEntity
    let comparison: WishlistComparisonEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !item.name.isEmpty {
                Text(item.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .padding(.horizontal, 4)
            }
            HStack(spacing: 10) {
                WishlistComparisonProductView(
                    imageURLs: item.imageURLs,
                    brand: item.brand,
                    categoryRaw: item.categoryRaw,
                    price: item.price
                )
                WishlistComparisonProductView(
                    imageURLs: comparison.imageURLs,
                    brand: comparison.brand,
                    categoryRaw: comparison.categoryRaw,
                    price: comparison.price
                )
            }
            if !item.goodPoint.isEmpty || !item.badPoint.isEmpty {
                HStack(spacing: 12) {
                    if !item.goodPoint.isEmpty {
                        Label(item.goodPoint, systemImage: "hand.thumbsup")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    if !item.badPoint.isEmpty {
                        Label(item.badPoint, systemImage: "hand.thumbsdown")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct WishlistComparisonProductView: View {
    let imageURLs: [String]
    let brand: String
    let categoryRaw: String
    let price: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WishlistThumbnail(imageURLs: imageURLs, size: nil)
                .aspectRatio(1, contentMode: .fit)
            VStack(alignment: .leading, spacing: 2) {
                if !brand.isEmpty { infoRow(brand) }
                if !categoryRaw.isEmpty { infoRow(categoryRaw) }
                if let p = price { infoRow("\(Int(p).formatted())원") }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func infoRow(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary).lineLimit(1)
    }
}

struct WishlistThumbnail: View {
    let imageURLs: [String]
    let size: CGFloat?

    var body: some View {
        let image = imageURLs.first.flatMap { ImageStorageService.shared.load(path: $0) }
        Group {
            if let img = image {
                Image(uiImage: img).resizable().scaledToFill().clipped()
            } else {
                Color.secondary.opacity(0.15)
                    .overlay { Image(systemName: "heart").foregroundStyle(.secondary) }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WishlistInfoGrid: View {
    let brand: String
    let categoryRaw: String
    let price: Double?
    let goodPoint: String
    let badPoint: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                if !brand.isEmpty { infoRow(brand) }
                if !categoryRaw.isEmpty { infoRow(categoryRaw) }
                if let p = price { infoRow("\(Int(p).formatted())원") }
            }
            if !goodPoint.isEmpty || !badPoint.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    if !goodPoint.isEmpty {
                        Label(goodPoint, systemImage: "hand.thumbsup")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    if !badPoint.isEmpty {
                        Label(badPoint, systemImage: "hand.thumbsdown")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
            }
        }
    }

    private func infoRow(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary).lineLimit(1)
    }
}

// MARK: - Image Picker

struct WishlistImagePickerView: View {
    @Binding var images: [UIImage]
    @Binding var galleryItems: [PhotosPickerItem]
    let height: CGFloat
    let maxImages: Int

    var body: some View {
        let count = images.count
        ZStack(alignment: .bottomTrailing) {
            if count > 0 {
                TabView {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img).resizable().scaledToFill().clipped()
                    }
                }
                .tabViewStyle(.page)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                PhotosPicker(selection: $galleryItems, maxSelectionCount: maxImages, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.12))
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: height < 250 ? 28 : 44))
                                .foregroundStyle(.secondary)
                            Text("사진 추가")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                }
            }
            if count > 0 {
                HStack(spacing: 6) {
                    Text("\(count)/\(maxImages)")
                        .font(.caption2).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.black.opacity(0.5), in: Capsule())
                    PhotosPicker(selection: $galleryItems, maxSelectionCount: maxImages - count, matching: .images) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2).foregroundStyle(.white)
                    }
                }
                .padding(8)
            }
        }
        .onChange(of: galleryItems) { _, newItems in
            Task { @MainActor in
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        images.append(img)
                    }
                }
                galleryItems = []
            }
        }
    }
}

// MARK: - Add / Edit Sheet

struct AddWishlistItemView: View {
    @EnvironmentObject var viewModel: WishlistViewModel
    @Environment(\.dismiss) private var dismiss

    var editing: WishlistItemEntity? = nil

    @State private var name = ""
    @State private var brand = ""
    @State private var categoryRaw = ""
    @State private var priceText = ""
    @State private var goodPoint = ""
    @State private var badPoint = ""
    @State private var selectedImages: [UIImage] = []
    @State private var galleryItems: [PhotosPickerItem] = []

    @State private var hasComparison = false
    @State private var compBrand = ""
    @State private var compCategoryRaw = ""
    @State private var compPriceText = ""
    @State private var compSelectedImages: [UIImage] = []
    @State private var compGalleryItems: [PhotosPickerItem] = []

    @State private var isSaving = false

    private let maxImages = 5
    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    imageSection
                    formSection
                    if hasComparison { comparisonSection }
                    if !hasComparison {
                        Button {
                            withAnimation { hasComparison = true }
                        } label: {
                            Text("비교 제품 등록")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .hideKeyboardOnTap()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(isEditing ? "위시리스트 수정" : "위시리스트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(isSaving)
                }
            }
        }
        .onAppear { populateIfEditing() }
    }

    // MARK: Image Section

    @ViewBuilder
    private var imageSection: some View {
        let h: CGFloat = hasComparison ? 180 : 320
        if hasComparison {
            HStack(spacing: 10) {
                WishlistImagePickerView(images: $selectedImages, galleryItems: $galleryItems, height: h, maxImages: maxImages)
                WishlistImagePickerView(images: $compSelectedImages, galleryItems: $compGalleryItems, height: h, maxImages: maxImages)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        } else {
            WishlistImagePickerView(images: $selectedImages, galleryItems: $galleryItems, height: h, maxImages: maxImages)
                .padding(.top, 16)
        }
    }

    // MARK: Form Fields

    private var formSection: some View {
        VStack(spacing: 0) {
            formRow(label: "이름", placeholder: "아이템 이름 (선택)") { TextField("", text: $name) }
            Divider().padding(.leading, 16)
            formRow(label: "브랜드", placeholder: "브랜드") { TextField("", text: $brand) }
            Divider().padding(.leading, 16)
            formRow(label: "카테고리", placeholder: "카테고리") { TextField("", text: $categoryRaw) }
            Divider().padding(.leading, 16)
            formRow(label: "가격", placeholder: "0") {
                TextField("", text: $priceText).keyboardType(.numberPad)
            }
            Divider().padding(.leading, 16)
            formRow(label: "장점", placeholder: "Good Point") { TextField("", text: $goodPoint) }
            Divider().padding(.leading, 16)
            formRow(label: "단점", placeholder: "Bad Point") { TextField("", text: $badPoint) }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("비교 제품")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation {
                        hasComparison = false
                        compBrand = ""; compCategoryRaw = ""; compPriceText = ""; compSelectedImages = []
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                formRow(label: "브랜드", placeholder: "브랜드") { TextField("", text: $compBrand) }
                Divider().padding(.leading, 16)
                formRow(label: "카테고리", placeholder: "카테고리") { TextField("", text: $compCategoryRaw) }
                Divider().padding(.leading, 16)
                formRow(label: "가격", placeholder: "0") {
                    TextField("", text: $compPriceText).keyboardType(.numberPad)
                }
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)

            Button {
                withAnimation { hasComparison = false }
            } label: {
                Text("비교 제품 등록")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }

    private func formRow<F: View>(label: String, placeholder: String, @ViewBuilder field: () -> F) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            field()
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Save

    private func save() {
        isSaving = true
        Task { @MainActor in
            var imagePaths: [String] = []
            for (idx, img) in selectedImages.enumerated() {
                let key = "\(UUID().uuidString)_\(idx)"
                if let path = try? ImageStorageService.shared.save(img, name: key) { imagePaths.append(path) }
            }

            var compEntity: WishlistComparisonEntity? = nil
            if hasComparison {
                var compPaths: [String] = []
                for (idx, img) in compSelectedImages.enumerated() {
                    let key = "\(UUID().uuidString)_comp_\(idx)"
                    if let path = try? ImageStorageService.shared.save(img, name: key) { compPaths.append(path) }
                }
                compEntity = WishlistComparisonEntity(
                    brand: compBrand,
                    categoryRaw: compCategoryRaw,
                    price: Double(compPriceText.filter { $0.isNumber }),
                    imageURLs: compPaths
                )
            }

            let nextOrder = (viewModel.items.map(\.sortOrder).max() ?? -1) + 1
            let item = WishlistItemEntity(
                id: editing?.id ?? UUID(),
                createdAt: editing?.createdAt ?? Date(),
                sortOrder: editing?.sortOrder ?? nextOrder,
                name: name,
                brand: brand,
                categoryRaw: categoryRaw,
                price: Double(priceText.filter { $0.isNumber }),
                imageURLs: imagePaths,
                goodPoint: goodPoint,
                badPoint: badPoint,
                comparison: compEntity
            )

            if isEditing { await viewModel.update(item) }
            else { await viewModel.add(item) }
            isSaving = false
            dismiss()
        }
    }

    // MARK: Populate (edit mode)

    private func populateIfEditing() {
        guard let item = editing else { return }
        name = item.name
        brand = item.brand
        categoryRaw = item.categoryRaw
        priceText = item.price.map { String(Int($0)) } ?? ""
        goodPoint = item.goodPoint
        badPoint = item.badPoint
        selectedImages = item.imageURLs.compactMap { ImageStorageService.shared.load(path: $0) }

        if let comp = item.comparison {
            hasComparison = true
            compBrand = comp.brand
            compCategoryRaw = comp.categoryRaw
            compPriceText = comp.price.map { String(Int($0)) } ?? ""
            compSelectedImages = comp.imageURLs.compactMap { ImageStorageService.shared.load(path: $0) }
        }
    }
}
