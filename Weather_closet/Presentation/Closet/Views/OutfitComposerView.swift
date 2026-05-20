import SwiftUI

// MARK: - UIKit Presentation Interceptor

private struct PresentationInterceptor: UIViewControllerRepresentable {
    let canDismiss: Bool
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.canDismiss = canDismiss
        context.coordinator.onAttempt = onAttempt
        DispatchQueue.main.async {
            var root: UIViewController? = uiViewController
            while let parent = root?.parent { root = parent }
            root?.presentationController?.delegate = context.coordinator
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var canDismiss = true
        var onAttempt: () -> Void = {}

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            canDismiss
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            onAttempt()
        }
    }
}

// MARK: - Text Color Palette

private let textColorPalette: [Color] = [
    .black, .white,
    Color(red: 0.95, green: 0.27, blue: 0.27),
    Color(red: 1.00, green: 0.58, blue: 0.00),
    Color(red: 1.00, green: 0.84, blue: 0.00),
    Color(red: 0.18, green: 0.80, blue: 0.44),
    Color(red: 0.20, green: 0.60, blue: 1.00),
    Color(red: 0.56, green: 0.27, blue: 0.68),
    Color(red: 1.00, green: 0.43, blue: 0.69),
]

// MARK: - Models

struct OutfitCanvasItem: Identifiable {
    let id: UUID
    let clothing: ClothingEntity
    var offset: CGSize = .zero
    var scale: CGFloat = 0.35
    var rotation: Angle = .zero
}

struct OutfitTextItem: Identifiable {
    let id: UUID
    var text: String
    var colorIndex: Int = 0
    var fontSize: CGFloat = 28
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var color: Color { textColorPalette[colorIndex] }
}

// MARK: - Outfit Composer View

struct OutfitComposerView: View {
    let clothingList: [ClothingEntity]
    @Environment(\.dismiss) private var dismiss

    @State private var items: [OutfitCanvasItem] = []
    @State private var textItems: [OutfitTextItem] = []
    @State private var selectedTextID: UUID? = nil
    @State private var backgroundColor: Color = .white
    @State private var showPicker = false

    // 드래그 삭제
    @State private var draggingItemID: UUID? = nil
    @State private var isOverDeleteZone = false

    // 닫기 확인
    @State private var showDiscardAlert = false

    // 인라인 텍스트 편집
    @State private var isTextEditing = false
    @State private var editingTextID: UUID? = nil
    @State private var liveEditText = ""
    @State private var liveColorIndex = 0
    @State private var liveFontScale: CGFloat = 1.0
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        NavigationStack {
            mainContent
                .background {
                    PresentationInterceptor(
                        canDismiss: items.isEmpty && textItems.isEmpty,
                        onAttempt: { showDiscardAlert = true }
                    )
                }
                .navigationTitle(isTextEditing ? "" : "조합 생성")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .confirmationDialog("저장하지 않고 나가시겠습니까?", isPresented: $showDiscardAlert, titleVisibility: .visible) {
            Button("나가기", role: .destructive) { dismiss() }
            Button("취소", role: .cancel) {}
        }
        .sheet(isPresented: $showPicker) {
            ClothingPickerSheet(clothingList: clothingList) { clothing in
                let item = OutfitCanvasItem(id: UUID(), clothing: clothing)
                items.insert(item, at: 0)
            }
        }
    }

    // MARK: - Main Content / Toolbar

    private var mainContent: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let cw = geo.size.width - 32
                let ch = geo.size.height - 32
                canvas(width: cw, height: ch)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            if isTextEditing { colorPaletteBar }
        }
        .overlay(alignment: .bottom) {
            if draggingItemID != nil { deleteZoneOverlay }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if isTextEditing {
                Button("취소") { cancelTextEditing() }
            } else {
                Button("닫기") {
                    if items.isEmpty && textItems.isEmpty { dismiss() }
                    else { showDiscardAlert = true }
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            if isTextEditing {
                Button("완료") { confirmTextEditing() }.fontWeight(.semibold)
            } else {
                Button("저장") { dismiss() }
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
                    canvasWidth: width,
                    onUpdate: { updated in
                        if let idx = items.firstIndex(where: { $0.id == updated.id }) {
                            items[idx] = updated
                        }
                        checkDeleteZone(offset: updated.offset, canvasHeight: height)
                    },
                    onDragStart: { id in draggingItemID = id },
                    onDragEnd: { id in
                        if isOverDeleteZone { items.removeAll { $0.id == id } }
                        draggingItemID = nil
                        isOverDeleteZone = false
                    }
                )
            }

            ForEach(textItems.reversed()) { text in
                CanvasTextItem(
                    item: text,
                    isSelected: selectedTextID == text.id,
                    onSelect: { selectedTextID = text.id },
                    onUpdate: { updated in
                        if let idx = textItems.firstIndex(where: { $0.id == updated.id }) {
                            textItems[idx] = updated
                        }
                        checkDeleteZone(offset: updated.offset, canvasHeight: height)
                    },
                    onEdit: { startTextEditing(editingID: text.id) },
                    onDragStart: { id in draggingItemID = id },
                    onDragEnd: { id in
                        if isOverDeleteZone {
                            textItems.removeAll { $0.id == id }
                            if selectedTextID == id { selectedTextID = nil }
                        }
                        draggingItemID = nil
                        isOverDeleteZone = false
                    }
                )
            }

            // 텍스트 편집 오버레이
            if isTextEditing {
                Color.black.opacity(0.5).allowsHitTesting(true)

                // 좌측 폰트 크기 슬라이더
                HStack(spacing: 0) {
                    Slider(value: $liveFontScale, in: 0.5...3.0)
                        .frame(width: height * 0.55)
                        .rotationEffect(.degrees(90))
                        .frame(width: 30, height: height * 0.55)
                        .tint(.white)
                        .padding(.leading, 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 텍스트 입력 필드
                TextField("텍스트 입력...", text: $liveEditText, axis: .vertical)
                    .focused($textFieldFocused)
                    .font(.system(size: 28 * liveFontScale, weight: .semibold))
                    .foregroundStyle(textColorPalette[liveColorIndex])
                    .multilineTextAlignment(.center)
                    .tint(.white)
                    .lineLimit(1...5)
                    .padding(.leading, 52)
                    .padding(.trailing, 16)
            }

        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { if !isTextEditing { selectedTextID = nil } }
        // clipShape 이후 overlay → 클리핑 없이 항상 최상단 표시
        .overlay(alignment: .topTrailing) {
            if !isTextEditing {
                VStack(spacing: 8) {
                    Button { startTextEditing(editingID: nil) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.45))
                                .frame(width: 44, height: 30)
                            Text("Aa")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Button { showPicker = true } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.45))
                                .frame(width: 44, height: 44)
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !isTextEditing {
                ColorPicker("", selection: $backgroundColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 44, height: 44)
                    .padding(10)
            }
        }
    }

    // MARK: - Color Palette Bar

    private var colorPaletteBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(textColorPalette.indices, id: \.self) { i in
                    Circle()
                        .fill(textColorPalette[i])
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().stroke(Color(uiColor: .label), lineWidth: liveColorIndex == i ? 2.5 : 0)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 1)
                        .onTapGesture { liveColorIndex = i }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Delete Zone Overlay

    private var deleteZoneOverlay: some View {
        VStack(spacing: 8) {
            Text("삭제하려면 끌어다 놓으세요")
                .font(.caption)
                .foregroundStyle(isOverDeleteZone ? Color.red : Color.red.opacity(0.7))
            ZStack {
                Circle()
                    .fill(isOverDeleteZone ? Color.red : Color.red.opacity(0.7))
                    .shadow(color: .red.opacity(0.4), radius: isOverDeleteZone ? 8 : 3)
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .frame(
                width: isOverDeleteZone ? 62 : 50,
                height: isOverDeleteZone ? 62 : 50
            )
            .animation(.easeInOut(duration: 0.15), value: isOverDeleteZone)
        }
        .padding(.bottom, 28)
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func checkDeleteZone(offset: CGSize, canvasHeight: CGFloat) {
        isOverDeleteZone = offset.height > (canvasHeight / 2 - 80)
    }

    private func startTextEditing(editingID: UUID?) {
        if let id = editingID, let item = textItems.first(where: { $0.id == id }) {
            editingTextID = id
            liveEditText = item.text
            liveColorIndex = item.colorIndex
            liveFontScale = item.scale
        } else {
            editingTextID = nil
            liveEditText = ""
            liveColorIndex = 0
            liveFontScale = 1.0
        }
        isTextEditing = true
        textFieldFocused = true
    }

    private func confirmTextEditing() {
        let t = liveEditText.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty {
            if let id = editingTextID,
               let idx = textItems.firstIndex(where: { $0.id == id }) {
                textItems[idx].text = t
                textItems[idx].colorIndex = liveColorIndex
                textItems[idx].scale = liveFontScale
            } else {
                let item = OutfitTextItem(
                    id: UUID(), text: t,
                    colorIndex: liveColorIndex, scale: liveFontScale
                )
                textItems.insert(item, at: 0)
                selectedTextID = item.id
            }
        }
        cancelTextEditing()
    }

    private func cancelTextEditing() {
        isTextEditing = false
        editingTextID = nil
        liveEditText = ""
        textFieldFocused = false
    }
}

// MARK: - Canvas Clothing Item

struct CanvasClothingItem: View {
    let item: OutfitCanvasItem
    let canvasWidth: CGFloat
    let onUpdate: (OutfitCanvasItem) -> Void
    let onDragStart: (UUID) -> Void
    let onDragEnd: (UUID) -> Void

    // 로컬 커밋 상태 — item prop 갱신 타이밍 차이로 인한 stale 캡처 방지
    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 0.35
    @State private var currentRotation: Angle = .zero
    @State private var dragStart: CGSize?
    @GestureState private var magnifyDelta: CGFloat = 1.0
    @GestureState private var rotationDelta: Angle = .zero

    private var image: UIImage? {
        if let bgPath = item.clothing.backgroundRemovedImageURL,
           let img = ImageStorageService.shared.load(path: bgPath) { return img }
        return item.clothing.imageURLs.first.flatMap { ImageStorageService.shared.load(path: $0) }
    }

    private var frameSize: CGFloat { canvasWidth * currentScale * magnifyDelta }

    var body: some View {
        Group {
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
        }
        .rotationEffect(currentRotation + rotationDelta)
        .offset(x: currentOffset.width, y: currentOffset.height)
        .gesture(
            SimultaneousGesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { val in
                        if dragStart == nil {
                            dragStart = currentOffset
                            onDragStart(item.id)
                        }
                        guard let s = dragStart else { return }
                        let newOffset = CGSize(
                            width: s.width + val.translation.width,
                            height: s.height + val.translation.height
                        )
                        currentOffset = newOffset
                        var updated = item
                        updated.offset = newOffset
                        updated.scale = currentScale
                        updated.rotation = currentRotation
                        onUpdate(updated)
                    }
                    .onEnded { _ in
                        dragStart = nil
                        onDragEnd(item.id)
                    },
                SimultaneousGesture(
                    MagnificationGesture()
                        .updating($magnifyDelta) { val, state, _ in state = val }
                        .onEnded { val in
                            let newScale = min(3.0, max(0.05, currentScale * val))
                            currentScale = newScale
                            var updated = item
                            updated.offset = currentOffset
                            updated.scale = newScale
                            updated.rotation = currentRotation
                            onUpdate(updated)
                        },
                    RotationGesture()
                        .updating($rotationDelta) { val, state, _ in state = val }
                        .onEnded { val in
                            let newRotation = currentRotation + val
                            currentRotation = newRotation
                            var updated = item
                            updated.offset = currentOffset
                            updated.scale = currentScale
                            updated.rotation = newRotation
                            onUpdate(updated)
                        }
                )
            )
        )
        .onAppear {
            currentOffset = item.offset
            currentScale = item.scale
            currentRotation = item.rotation
        }
    }
}

// MARK: - Canvas Text Item

struct CanvasTextItem: View {
    let item: OutfitTextItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (OutfitTextItem) -> Void
    let onEdit: () -> Void
    let onDragStart: (UUID) -> Void
    let onDragEnd: (UUID) -> Void

    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var dragStart: CGSize?
    @GestureState private var magnifyDelta: CGFloat = 1.0
    @GestureState private var rotationDelta: Angle = .zero

    var body: some View {
        Text(item.text)
            .font(.system(size: item.fontSize * currentScale * magnifyDelta, weight: .semibold))
            .foregroundStyle(item.color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8).padding(.vertical, 6)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor.opacity(0.7), lineWidth: 1.5)
                }
            }
            .rotationEffect(currentRotation + rotationDelta)
            .offset(x: currentOffset.width, y: currentOffset.height)
            .gesture(
                SimultaneousGesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { val in
                            if dragStart == nil {
                                dragStart = currentOffset
                                onDragStart(item.id)
                            }
                            guard let s = dragStart else { return }
                            onSelect()
                            let newOffset = CGSize(
                                width: s.width + val.translation.width,
                                height: s.height + val.translation.height
                            )
                            currentOffset = newOffset
                            var updated = item
                            updated.offset = newOffset
                            updated.scale = currentScale
                            updated.rotation = currentRotation
                            onUpdate(updated)
                        }
                        .onEnded { _ in
                            dragStart = nil
                            onDragEnd(item.id)
                        },
                    SimultaneousGesture(
                        MagnificationGesture()
                            .updating($magnifyDelta) { val, state, _ in state = val }
                            .onEnded { val in
                                let newScale = min(4.0, max(0.2, currentScale * val))
                                currentScale = newScale
                                var updated = item
                                updated.offset = currentOffset
                                updated.scale = newScale
                                updated.rotation = currentRotation
                                onUpdate(updated)
                            },
                        RotationGesture()
                            .updating($rotationDelta) { val, state, _ in state = val }
                            .onEnded { val in
                                let newRotation = currentRotation + val
                                currentRotation = newRotation
                                var updated = item
                                updated.offset = currentOffset
                                updated.scale = currentScale
                                updated.rotation = newRotation
                                onUpdate(updated)
                            }
                    )
                )
            )
            .onTapGesture { onSelect() }
            .simultaneousGesture(TapGesture(count: 2).onEnded { onEdit() })
            .onAppear {
                currentOffset = item.offset
                currentScale = item.scale
                currentRotation = item.rotation
            }
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
