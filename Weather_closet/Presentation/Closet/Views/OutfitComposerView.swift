import SwiftUI
import UIKit

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
    var editingOutfit: OutfitEntity? = nil
    @EnvironmentObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [OutfitCanvasItem] = []
    @State private var textItems: [OutfitTextItem] = []
    @State private var selectedTextID: UUID? = nil
    @State private var backgroundColor: Color = .white
    @State private var showPicker = false
    @State private var canvasSize: CGSize = .zero

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
                .navigationTitle(isTextEditing ? "" : (editingOutfit == nil ? "조합 생성" : "조합 수정"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .onAppear { loadEditingOutfitIfNeeded() }
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
                    .onAppear { canvasSize = CGSize(width: cw, height: ch) }
                    .onChange(of: geo.size) { _, _ in canvasSize = CGSize(width: cw, height: ch) }
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
                Button("저장") {
                    Task { await saveOutfit() }
                }
                .fontWeight(.semibold)
                .disabled(items.isEmpty && textItems.isEmpty)
            }
        }
    }

    // MARK: - Canvas

    private func canvas(width: CGFloat, height: CGFloat, showOverlays: Bool = true) -> some View {
        ZStack {
            backgroundColor

            ForEach(items.reversed()) { item in
                CanvasClothingItem(
                    item: item,
                    canvasWidth: width,
                    onUpdate: { updated, pureDrag in
                        if let idx = items.firstIndex(where: { $0.id == updated.id }) {
                            items[idx] = updated
                        }
                        if pureDrag { checkDeleteZone(offset: updated.offset, canvasHeight: height) }
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
                    onUpdate: { updated, pureDrag in
                        if let idx = textItems.firstIndex(where: { $0.id == updated.id }) {
                            textItems[idx] = updated
                        }
                        if pureDrag { checkDeleteZone(offset: updated.offset, canvasHeight: height) }
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
            if showOverlays && !isTextEditing {
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
            if showOverlays && !isTextEditing {
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

    private func loadEditingOutfitIfNeeded() {
        guard let existing = editingOutfit, items.isEmpty else { return }
        let clothingByID = Dictionary(uniqueKeysWithValues: clothingList.map { ($0.id, $0) })

        if !existing.canvasStates.isEmpty {
            items = existing.canvasStates.compactMap { state in
                clothingByID[state.clothingID].map {
                    OutfitCanvasItem(
                        id: UUID(),
                        clothing: $0,
                        offset: CGSize(width: state.offsetX, height: state.offsetY),
                        scale: state.scale,
                        rotation: Angle(radians: state.rotationRadians)
                    )
                }
            }
        } else {
            items = existing.clothingIDs.compactMap { id in
                clothingByID[id].map { OutfitCanvasItem(id: UUID(), clothing: $0) }
            }
        }

        textItems = existing.textStates.map { state in
            OutfitTextItem(
                id: UUID(),
                text: state.text,
                colorIndex: state.colorIndex,
                fontSize: state.fontSize,
                offset: CGSize(width: state.offsetX, height: state.offsetY),
                scale: state.scale,
                rotation: Angle(radians: state.rotationRadians)
            )
        }
    }

    private func saveOutfit() async {
        let canvasStates = items.map { item in
            CanvasItemState(
                clothingID: item.clothing.id,
                offsetX: item.offset.width,
                offsetY: item.offset.height,
                scale: item.scale,
                rotationRadians: item.rotation.radians
            )
        }
        let savedTextStates = textItems.map { text in
            TextItemState(
                text: text.text,
                colorIndex: text.colorIndex,
                fontSize: text.fontSize,
                offsetX: text.offset.width,
                offsetY: text.offset.height,
                scale: text.scale,
                rotationRadians: text.rotation.radians
            )
        }

        var imageURL: String? = nil
        let cw = canvasSize.width
        let ch = canvasSize.height
        if cw > 0 && ch > 0 {
            let rendered = ThumbnailCanvasView(
                items: items,
                textItems: textItems,
                backgroundColor: backgroundColor,
                width: cw,
                height: ch
            )
            let renderer = ImageRenderer(content: rendered)
            renderer.scale = UIScreen.main.scale
            if let img = renderer.uiImage {
                imageURL = try? ImageStorageService.shared.savePNG(img, name: UUID().uuidString)
            }
        }

        if let existing = editingOutfit {
            var updated = existing
            updated.clothingIDs = items.map { $0.clothing.id }
            updated.canvasStates = canvasStates
            updated.textStates = savedTextStates
            updated.imageURL = imageURL
            await viewModel.updateOutfit(updated)
        } else {
            let outfit = OutfitEntity(
                id: UUID(),
                name: "",
                clothingIDs: items.map { $0.clothing.id },
                canvasStates: canvasStates,
                textStates: savedTextStates,
                tags: [],
                note: "",
                createdAt: Date(),
                imageURL: imageURL
            )
            await viewModel.saveOutfit(outfit)
        }
        dismiss()
    }

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

// MARK: - Static Thumbnail Canvas (for ImageRenderer — no @State, no interactive controls)

private struct ThumbnailCanvasView: View {
    let items: [OutfitCanvasItem]
    let textItems: [OutfitTextItem]
    let backgroundColor: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            backgroundColor
            ForEach(items.reversed()) { item in
                ThumbnailClothingItem(item: item, canvasWidth: width)
            }
            ForEach(textItems.reversed()) { text in
                Text(text.text)
                    .font(.system(size: text.fontSize * text.scale, weight: .semibold))
                    .foregroundStyle(text.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .rotationEffect(text.rotation)
                    .offset(x: text.offset.width, y: text.offset.height)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ThumbnailClothingItem: View {
    let item: OutfitCanvasItem
    let canvasWidth: CGFloat

    private var image: UIImage? {
        if let bgPath = item.clothing.backgroundRemovedImageURL,
           let img = ImageStorageService.shared.load(path: bgPath) { return img }
        return item.clothing.imageURLs.first.flatMap { ImageStorageService.shared.load(path: $0) }
    }

    var body: some View {
        let frameSize = canvasWidth * item.scale
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
            }
        }
        .rotationEffect(item.rotation)
        .offset(x: item.offset.width, y: item.offset.height)
    }
}

// MARK: - UIKit Gesture Layer (pan blocks pinch/rotation via shouldReceive)

private struct CanvasItemGestureView: UIViewRepresentable {
    let onPanBegan: () -> Void
    let onPanChanged: (CGSize) -> Void    // incremental delta
    let onPanEnded: () -> Void
    let onScaleDelta: (CGFloat) -> Void   // incremental multiplier
    let onRotationDelta: (Double) -> Void // incremental radians
    var onTap: (() -> Void)? = nil
    var onDoubleTap: (() -> Void)? = nil

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                              action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        view.addGestureRecognizer(pinch)

        let rot = UIRotationGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleRotation(_:)))
        rot.delegate = context.coordinator
        view.addGestureRecognizer(rot)

        if onTap != nil {
            let tap = UITapGestureRecognizer(target: context.coordinator,
                                              action: #selector(Coordinator.handleTap))
            view.addGestureRecognizer(tap)
        }
        if onDoubleTap != nil {
            let dbl = UITapGestureRecognizer(target: context.coordinator,
                                              action: #selector(Coordinator.handleDoubleTap))
            dbl.numberOfTapsRequired = 2
            view.addGestureRecognizer(dbl)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.host = self
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var host: CanvasItemGestureView?
        private var isPanning = false
        private var lastWindowLocation: CGPoint = .zero

        // pinch + rotation can be simultaneous; pan is exclusive
        func gestureRecognizer(_ gr: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            !(gr is UIPanGestureRecognizer || other is UIPanGestureRecognizer)
        }

        // block new pinch/rotation touches while pan is active
        func gestureRecognizer(_ gr: UIGestureRecognizer,
                               shouldReceive touch: UITouch) -> Bool {
            if isPanning && (gr is UIPinchGestureRecognizer || gr is UIRotationGestureRecognizer) {
                return false
            }
            return true
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            // 윈도우 좌표계로 델타 계산 — 아이템의 scale/rotation 변환에 영향받지 않음
            let windowLoc = g.location(in: g.view?.window)
            switch g.state {
            case .began:
                lastWindowLocation = windowLoc
                isPanning = true
                host?.onPanBegan()
            case .changed:
                let delta = CGSize(
                    width: windowLoc.x - lastWindowLocation.x,
                    height: windowLoc.y - lastWindowLocation.y
                )
                lastWindowLocation = windowLoc
                host?.onPanChanged(delta)
            case .ended, .cancelled:
                isPanning = false
                host?.onPanEnded()
            default: break
            }
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            switch g.state {
            case .began:
                g.scale = 1.0
            case .changed:
                host?.onScaleDelta(g.scale)
                g.scale = 1.0
            case .ended, .cancelled:
                if g.scale != 1.0 { host?.onScaleDelta(g.scale) }
            default: break
            }
        }

        @objc func handleRotation(_ g: UIRotationGestureRecognizer) {
            switch g.state {
            case .began:
                g.rotation = 0
            case .changed:
                host?.onRotationDelta(Double(g.rotation))
                g.rotation = 0
            case .ended, .cancelled:
                if g.rotation != 0 { host?.onRotationDelta(Double(g.rotation)) }
            default: break
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) { host?.onTap?() }
        @objc func handleDoubleTap(_ g: UITapGestureRecognizer) { host?.onDoubleTap?() }
    }
}

// MARK: - Canvas Clothing Item

struct CanvasClothingItem: View {
    let item: OutfitCanvasItem
    let canvasWidth: CGFloat
    let onUpdate: (OutfitCanvasItem, Bool) -> Void
    let onDragStart: (UUID) -> Void
    let onDragEnd: (UUID) -> Void

    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 0.35
    @State private var currentRotation: Angle = .zero

    private var image: UIImage? {
        if let bgPath = item.clothing.backgroundRemovedImageURL,
           let img = ImageStorageService.shared.load(path: bgPath) { return img }
        return item.clothing.imageURLs.first.flatMap { ImageStorageService.shared.load(path: $0) }
    }

    var body: some View {
        let frameSize = canvasWidth * currentScale
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
        .overlay(
            CanvasItemGestureView(
                onPanBegan: { onDragStart(item.id) },
                onPanChanged: { delta in
                    let newOffset = CGSize(
                        width: currentOffset.width + delta.width,
                        height: currentOffset.height + delta.height
                    )
                    currentOffset = newOffset
                    var updated = item
                    updated.offset = newOffset
                    updated.scale = currentScale
                    updated.rotation = currentRotation
                    onUpdate(updated, true)
                },
                onPanEnded: { onDragEnd(item.id) },
                onScaleDelta: { factor in
                    currentScale = min(3.0, max(0.05, currentScale * factor))
                    var updated = item
                    updated.offset = currentOffset
                    updated.scale = currentScale
                    updated.rotation = currentRotation
                    onUpdate(updated, false)
                },
                onRotationDelta: { radians in
                    currentRotation += Angle(radians: radians)
                    var updated = item
                    updated.offset = currentOffset
                    updated.scale = currentScale
                    updated.rotation = currentRotation
                    onUpdate(updated, false)
                }
            )
        )
        .rotationEffect(currentRotation)
        .offset(x: currentOffset.width, y: currentOffset.height)
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
    let onUpdate: (OutfitTextItem, Bool) -> Void
    let onEdit: () -> Void
    let onDragStart: (UUID) -> Void
    let onDragEnd: (UUID) -> Void

    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero

    var body: some View {
        Text(item.text)
            .font(.system(size: item.fontSize * currentScale, weight: .semibold))
            .foregroundStyle(item.color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8).padding(.vertical, 6)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor.opacity(0.7), lineWidth: 1.5)
                }
            }
            .overlay(
                CanvasItemGestureView(
                    onPanBegan: { onDragStart(item.id) },
                    onPanChanged: { delta in
                        let newOffset = CGSize(
                            width: currentOffset.width + delta.width,
                            height: currentOffset.height + delta.height
                        )
                        currentOffset = newOffset
                        onSelect()
                        var updated = item
                        updated.offset = newOffset
                        updated.scale = currentScale
                        updated.rotation = currentRotation
                        onUpdate(updated, true)
                    },
                    onPanEnded: { onDragEnd(item.id) },
                    onScaleDelta: { factor in
                        currentScale = min(4.0, max(0.2, currentScale * factor))
                        var updated = item
                        updated.offset = currentOffset
                        updated.scale = currentScale
                        updated.rotation = currentRotation
                        onUpdate(updated, false)
                    },
                    onRotationDelta: { radians in
                        currentRotation += Angle(radians: radians)
                        var updated = item
                        updated.offset = currentOffset
                        updated.scale = currentScale
                        updated.rotation = currentRotation
                        onUpdate(updated, false)
                    },
                    onTap: { onSelect() },
                    onDoubleTap: { onEdit() }
                )
            )
            .rotationEffect(currentRotation)
            .offset(x: currentOffset.width, y: currentOffset.height)
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
