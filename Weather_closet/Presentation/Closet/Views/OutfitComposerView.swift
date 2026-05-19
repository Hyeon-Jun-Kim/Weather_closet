import SwiftUI

// MARK: - Canvas Item Model

struct OutfitCanvasItem: Identifiable {
    let id: UUID
    let clothing: ClothingEntity
    var offset: CGSize = .zero
    var scale: CGFloat = 0.35
}

// MARK: - Outfit Composer View

struct OutfitComposerView: View {
    let clothingList: [ClothingEntity]
    @Environment(\.dismiss) private var dismiss

    @State private var items: [OutfitCanvasItem] = []
    @State private var selectedID: UUID? = nil
    @State private var backgroundColor: Color = .white
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let canvasWidth = geo.size.width - 32
                    let canvasHeight = canvasWidth * 4 / 3
                    VStack(spacing: 0) {
                        canvas(width: canvasWidth, height: canvasHeight)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        itemList
                    }
                }
            }
            .navigationTitle("조합 생성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            ClothingPickerSheet(clothingList: clothingList) { clothing in
                let item = OutfitCanvasItem(id: UUID(), clothing: clothing)
                items.insert(item, at: 0)
                selectedID = item.id
            }
        }
    }

    // MARK: - Canvas

    private func canvas(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            backgroundColor

            ForEach(items.reversed()) { item in
                CanvasClothingItem(
                    item: item,
                    isSelected: selectedID == item.id,
                    canvasWidth: width,
                    onSelect: { selectedID = item.id },
                    onUpdate: { updated in
                        if let idx = items.firstIndex(where: { $0.id == updated.id }) {
                            items[idx] = updated
                        }
                    }
                )
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ColorPicker("", selection: $backgroundColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 44, height: 44)
                        .padding(10)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { selectedID = nil }
    }

    // MARK: - Item List

    private var itemList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("아이템")
                    .font(.subheadline).fontWeight(.semibold)
                Button {
                    showPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)

            if items.isEmpty {
                Text("+ 버튼으로 아이템을 추가하세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(16)
            } else {
                List {
                    ForEach(items) { item in
                        OutfitItemRow(item: item, isSelected: selectedID == item.id)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedID = item.id }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onMove { src, dst in items.move(fromOffsets: src, toOffset: dst) }
                    .onDelete { offsets in
                        let removedIDs = offsets.map { items[$0].id }
                        items.remove(atOffsets: offsets)
                        if let sel = selectedID, removedIDs.contains(sel) { selectedID = nil }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Canvas Clothing Item

struct CanvasClothingItem: View {
    let item: OutfitCanvasItem
    let isSelected: Bool
    let canvasWidth: CGFloat
    let onSelect: () -> Void
    let onUpdate: (OutfitCanvasItem) -> Void

    @GestureState private var dragDelta: CGSize = .zero
    @GestureState private var magnifyDelta: CGFloat = 1.0

    private var image: UIImage? {
        if let bgPath = item.clothing.backgroundRemovedImageURL,
           let img = ImageStorageService.shared.load(path: bgPath) {
            return img
        }
        return item.clothing.imageURLs.first.flatMap { ImageStorageService.shared.load(path: $0) }
    }

    private var displayScale: CGFloat { item.scale * magnifyDelta }
    private var frameSize: CGFloat { canvasWidth * displayScale }

    var body: some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: frameSize, height: frameSize)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: frameSize, height: frameSize)
                    .overlay { Image(systemName: "tshirt").foregroundStyle(.secondary) }
            }

            if isSelected { SelectionHandleOverlay(size: frameSize) }
        }
        .offset(x: item.offset.width + dragDelta.width, y: item.offset.height + dragDelta.height)
        .gesture(
            SimultaneousGesture(
                DragGesture(minimumDistance: 2)
                    .updating($dragDelta) { val, state, _ in state = val.translation }
                    .onChanged { _ in onSelect() }
                    .onEnded { val in
                        var updated = item
                        updated.offset = CGSize(
                            width: item.offset.width + val.translation.width,
                            height: item.offset.height + val.translation.height
                        )
                        onUpdate(updated)
                    },
                MagnificationGesture()
                    .updating($magnifyDelta) { val, state, _ in state = val }
                    .onChanged { _ in onSelect() }
                    .onEnded { val in
                        var updated = item
                        updated.scale = min(1.5, max(0.1, item.scale * val))
                        onUpdate(updated)
                    }
            )
        )
        .onTapGesture { onSelect() }
    }
}

// MARK: - Selection Handle Overlay

struct SelectionHandleOverlay: View {
    let size: CGFloat
    private let handleSize: CGFloat = 9
    private let handles: [(CGFloat, CGFloat)] = [
        (-0.5, -0.5), (0, -0.5), (0.5, -0.5),
        (-0.5,  0  ),             (0.5,  0  ),
        (-0.5,  0.5), (0,  0.5), (0.5,  0.5)
    ]

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1.5)
                .frame(width: size, height: size)
            ForEach(Array(handles.enumerated()), id: \.offset) { _, pos in
                ZStack {
                    Rectangle().fill(Color.white)
                    Rectangle().stroke(Color.accentColor, lineWidth: 1)
                }
                .frame(width: handleSize, height: handleSize)
                .offset(x: pos.0 * size, y: pos.1 * size)
            }
        }
    }
}

// MARK: - Item Row

struct OutfitItemRow: View {
    let item: OutfitCanvasItem
    let isSelected: Bool

    private var displayImage: UIImage? {
        if let bgPath = item.clothing.backgroundRemovedImageURL,
           let img = ImageStorageService.shared.load(path: bgPath) { return img }
        return item.clothing.imageURLs.first.flatMap { ImageStorageService.shared.load(path: $0) }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(item.clothing.category.rawValue)
                .font(.caption2).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color.secondary.opacity(0.6), in: Capsule())
                .lineLimit(1).fixedSize()

            Group {
                if let img = displayImage {
                    Image(uiImage: img).resizable().scaledToFit()
                } else {
                    Color.secondary.opacity(0.15)
                        .overlay { Image(systemName: "tshirt").foregroundStyle(.secondary) }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.clothing.name.isEmpty ? "이름 없음" : item.clothing.name)
                    .font(.subheadline).lineLimit(1)
                if !item.clothing.brand.isEmpty {
                    Text(item.clothing.brand).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(
            isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}

// MARK: - Clothing Picker Sheet

struct ClothingPickerSheet: View {
    let clothingList: [ClothingEntity]
    let onPick: (ClothingEntity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var activeCategory: ClothingCategory? = nil

    private var categories: [ClothingCategory] {
        ClothingCategory.allCases.filter { cat in clothingList.contains { $0.category == cat } }
    }

    private var filtered: [ClothingEntity] {
        guard let cat = activeCategory else { return clothingList }
        return clothingList.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(label: "전체", isSelected: activeCategory == nil) { activeCategory = nil }
                        ForEach(categories, id: \.self) { cat in
                            categoryChip(label: cat.rawValue, isSelected: activeCategory == cat) { activeCategory = cat }
                        }
                    }
                    .padding(.horizontal).padding(.vertical, 10)
                }
                Divider()
                if filtered.isEmpty {
                    ContentUnavailableView("옷이 없습니다", systemImage: "tshirt")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filtered) { clothing in
                        Button {
                            onPick(clothing)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                thumbnailView(for: clothing)
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(clothing.name.isEmpty ? "이름 없음" : clothing.name)
                                        .font(.subheadline).foregroundStyle(.primary)
                                    Text(clothing.category.rawValue)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("아이템 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            }
        }
    }

    private func categoryChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func thumbnailView(for clothing: ClothingEntity) -> some View {
        if let path = clothing.imageURLs.first,
           let img = ImageStorageService.shared.load(path: path) {
            Image(uiImage: img).resizable().scaledToFill().clipped()
        } else {
            Color.secondary.opacity(0.15)
                .overlay { Image(systemName: "tshirt").foregroundStyle(.secondary) }
        }
    }
}
