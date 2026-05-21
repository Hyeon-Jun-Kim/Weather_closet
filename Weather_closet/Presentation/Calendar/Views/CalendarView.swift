import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var showOutfitSheet = false
    @State private var showPurchaseSheet = false
    @State private var showSaleSheet = false
    @State private var eventToEdit: CalendarEventEntity?
    @State private var eventToDelete: CalendarEventEntity?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("캘린더")
                    .font(.title).fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                DatePicker(
                    "날짜 선택",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: viewModel.selectedDate) { _, newDate in
                    Task { await viewModel.loadEvents(for: newDate) }
                }

                Divider()

                ZStack {
                    if viewModel.eventsForSelectedDate.isEmpty {
                        CalendarEmptyStateView(
                            onAddOutfit:   { showOutfitSheet = true },
                            onAddPurchase: { showPurchaseSheet = true },
                            onAddSale:     { showSaleSheet = true }
                        )
                    } else {
                        List {
                            ForEach(viewModel.eventsForSelectedDate) { event in
                                CalendarEventRow(event: event)
                                    .contextMenu {
                                        Button { eventToEdit = event } label: {
                                            Label("수정", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            eventToDelete = event
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            eventToDelete = event
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadEvents(for: viewModel.selectedDate)
                await viewModel.loadClothingList()
            }
            .alert("삭제", isPresented: Binding(
                get: { eventToDelete != nil },
                set: { if !$0 { eventToDelete = nil } }
            )) {
                Button("삭제", role: .destructive) {
                    if let event = eventToDelete {
                        Task { await viewModel.deleteEvent(id: event.id) }
                        eventToDelete = nil
                    }
                }
                Button("취소", role: .cancel) { eventToDelete = nil }
            } message: {
                Text("이 기록을 삭제하시겠습니까?")
            }
            .sheet(isPresented: $showOutfitSheet) {
                OutfitRecordSheet().environmentObject(viewModel)
            }
            .sheet(isPresented: $showPurchaseSheet) {
                PurchaseRecordSheet().environmentObject(viewModel)
            }
            .sheet(isPresented: $showSaleSheet) {
                SaleRecordSheet().environmentObject(viewModel)
            }
            .sheet(item: $eventToEdit) { event in
                EventEditSheet(event: event).environmentObject(viewModel)
            }
        }
    }
}

// MARK: - 착용 기록 시트

struct OutfitRecordSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIDs: Set<UUID> = []
    @State private var activeCategory: ClothingCategory?
    @State private var note = ""

    private var availableCategories: [ClothingCategory] {
        ClothingCategory.allCases.filter { cat in
            viewModel.clothingList.contains { $0.category == cat }
        }
    }

    private var itemsForCategory: [ClothingEntity] {
        guard let cat = activeCategory else { return [] }
        return viewModel.clothingList.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 카테고리 칩
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Button { activeCategory = cat } label: {
                                Text(cat.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(activeCategory == cat ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundStyle(activeCategory == cat ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                Divider()

                // 옷 목록
                Group {
                    if activeCategory == nil {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("카테고리를 선택해주세요")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if itemsForCategory.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tshirt")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("등록된 옷이 없습니다")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(itemsForCategory) { clothing in
                            Button {
                                if selectedIDs.contains(clothing.id) {
                                    selectedIDs.remove(clothing.id)
                                } else {
                                    selectedIDs.insert(clothing.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
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
                                                        .foregroundStyle(.secondary)
                                                }
                                        }
                                    }
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(clothing.name)
                                            .foregroundStyle(.primary)
                                            .font(.subheadline)
                                        if !clothing.subCategory.isEmpty {
                                            Text(clothing.subCategory)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: selectedIDs.contains(clothing.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIDs.contains(clothing.id) ? Color.accentColor : .secondary)
                                        .font(.title3)
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .listStyle(.plain)
                    }
                }

                // 선택 현황 + 메모
                if !selectedIDs.isEmpty {
                    Divider()
                    Text("선택된 옷 \(selectedIDs.count)개")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Divider()
                HStack {
                    Image(systemName: "pencil").foregroundStyle(.secondary)
                    TextField("코디 메모 (선택)", text: $note)
                }
                .padding()
            }
            .navigationTitle("착용 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await viewModel.recordOutfit(clothingIDs: Array(selectedIDs), note: note)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 구매 기록 시트

struct PurchaseRecordSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var clothingName = ""
    @State private var price = ""
    @State private var place = ""
    @State private var note = ""

    private var formattedPriceBinding: Binding<String> {
        Binding(
            get: {
                guard !price.isEmpty, let v = Int(price) else { return price }
                return v.formatted()
            },
            set: { price = $0.filter { $0.isNumber } }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("구매 정보") {
                    TextField("상품명", text: $clothingName)
                    HStack {
                        Text("가격").foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: formattedPriceBinding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 130)
                        Text("원").foregroundStyle(.secondary).font(.subheadline)
                    }
                    TextField("구매처", text: $place)
                }
                Section("메모 (선택)") {
                    TextField("메모", text: $note, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("구매 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await viewModel.recordPurchase(
                                clothingName: clothingName,
                                price: Double(price) ?? 0,
                                place: place,
                                note: note
                            )
                            dismiss()
                        }
                    }
                    .disabled(clothingName.isEmpty)
                }
            }
        }
    }
}

// MARK: - 판매 기록 시트

struct SaleRecordSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var clothingName = ""
    @State private var price = ""
    @State private var platform = ""
    @State private var note = ""

    private var formattedPriceBinding: Binding<String> {
        Binding(
            get: {
                guard !price.isEmpty, let v = Int(price) else { return price }
                return v.formatted()
            },
            set: { price = $0.filter { $0.isNumber } }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("판매 정보") {
                    TextField("상품명", text: $clothingName)
                    HStack {
                        Text("가격").foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: formattedPriceBinding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 130)
                        Text("원").foregroundStyle(.secondary).font(.subheadline)
                    }
                    TextField("판매 플랫폼", text: $platform)
                }
                Section("메모 (선택)") {
                    TextField("메모", text: $note, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("판매 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await viewModel.recordSale(
                                clothingName: clothingName,
                                price: Double(price) ?? 0,
                                platform: platform,
                                note: note
                            )
                            dismiss()
                        }
                    }
                    .disabled(clothingName.isEmpty)
                }
            }
        }
    }
}

// MARK: - 이벤트 수정 시트

struct EventEditSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    let event: CalendarEventEntity

    var body: some View {
        switch event.type {
        case .outfit(let log):
            EditOutfitSheet(event: event, log: log).environmentObject(viewModel)
        case .purchase(let log):
            EditPurchaseSheet(event: event, log: log).environmentObject(viewModel)
        case .sale(let log):
            EditSaleSheet(event: event, log: log).environmentObject(viewModel)
        }
    }
}

struct EditOutfitSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    let event: CalendarEventEntity
    let log: OutfitLogEntity

    @State private var selectedIDs: Set<UUID>
    @State private var activeCategory: ClothingCategory?
    @State private var note: String

    init(event: CalendarEventEntity, log: OutfitLogEntity) {
        self.event = event
        self.log = log
        _selectedIDs = State(initialValue: Set(log.clothingIDs))
        _note = State(initialValue: log.note)
    }

    private var availableCategories: [ClothingCategory] {
        ClothingCategory.allCases.filter { cat in
            viewModel.clothingList.contains { $0.category == cat }
        }
    }

    private var itemsForCategory: [ClothingEntity] {
        guard let cat = activeCategory else { return [] }
        return viewModel.clothingList.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Button { activeCategory = cat } label: {
                                Text(cat.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(activeCategory == cat ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundStyle(activeCategory == cat ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal).padding(.vertical, 10)
                }
                Divider()
                if activeCategory == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text("카테고리를 선택해주세요").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(itemsForCategory) { clothing in
                        Button {
                            if selectedIDs.contains(clothing.id) { selectedIDs.remove(clothing.id) }
                            else { selectedIDs.insert(clothing.id) }
                        } label: {
                            HStack(spacing: 12) {
                                Group {
                                    if let path = clothing.imageURLs.first,
                                       let image = ImageStorageService.shared.load(path: path) {
                                        Image(uiImage: image).resizable().scaledToFill()
                                    } else {
                                        Color.secondary.opacity(0.15).overlay { Image(systemName: "tshirt").foregroundStyle(.secondary) }
                                    }
                                }
                                .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(clothing.name).foregroundStyle(.primary).font(.subheadline)
                                    if !clothing.subCategory.isEmpty {
                                        Text(clothing.subCategory).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: selectedIDs.contains(clothing.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIDs.contains(clothing.id) ? Color.accentColor : .secondary)
                                    .font(.title3)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
                if !selectedIDs.isEmpty {
                    Divider()
                    Text("선택된 옷 \(selectedIDs.count)개")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.top, 8)
                }
                Divider()
                HStack {
                    Image(systemName: "pencil").foregroundStyle(.secondary)
                    TextField("코디 메모 (선택)", text: $note)
                }
                .padding()
            }
            .navigationTitle("착용 기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            let updated = CalendarEventEntity(
                                id: event.id, date: event.date,
                                type: .outfit(OutfitLogEntity(outfitID: log.outfitID, clothingIDs: Array(selectedIDs), weather: log.weather, note: note))
                            )
                            await viewModel.updateEvent(updated)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct EditPurchaseSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    let event: CalendarEventEntity
    let log: PurchaseLogEntity

    @State private var clothingName: String
    @State private var price: String
    @State private var place: String
    @State private var note: String

    init(event: CalendarEventEntity, log: PurchaseLogEntity) {
        self.event = event; self.log = log
        _clothingName = State(initialValue: log.clothingName)
        _price = State(initialValue: log.price > 0 ? String(Int(log.price)) : "")
        _place = State(initialValue: log.place)
        _note = State(initialValue: log.note)
    }

    private var formattedPriceBinding: Binding<String> {
        Binding(
            get: { guard !price.isEmpty, let v = Int(price) else { return price }; return v.formatted() },
            set: { price = $0.filter { $0.isNumber } }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("구매 정보") {
                    TextField("상품명", text: $clothingName)
                    HStack {
                        Text("가격").foregroundStyle(.secondary); Spacer()
                        TextField("0", text: formattedPriceBinding).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 130)
                        Text("원").foregroundStyle(.secondary).font(.subheadline)
                    }
                    TextField("구매처", text: $place)
                }
                Section("메모 (선택)") { TextField("메모", text: $note, axis: .vertical).lineLimit(3...) }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("구매 기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            let updated = CalendarEventEntity(
                                id: event.id, date: event.date,
                                type: .purchase(PurchaseLogEntity(clothingID: log.clothingID, clothingName: clothingName, price: Double(price) ?? 0, place: place, note: note))
                            )
                            await viewModel.updateEvent(updated); dismiss()
                        }
                    }
                    .disabled(clothingName.isEmpty)
                }
            }
        }
    }
}

struct EditSaleSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    let event: CalendarEventEntity
    let log: SaleLogEntity

    @State private var clothingName: String
    @State private var price: String
    @State private var platform: String
    @State private var note: String

    init(event: CalendarEventEntity, log: SaleLogEntity) {
        self.event = event; self.log = log
        _clothingName = State(initialValue: log.clothingName)
        _price = State(initialValue: log.price > 0 ? String(Int(log.price)) : "")
        _platform = State(initialValue: log.platform)
        _note = State(initialValue: log.note)
    }

    private var formattedPriceBinding: Binding<String> {
        Binding(
            get: { guard !price.isEmpty, let v = Int(price) else { return price }; return v.formatted() },
            set: { price = $0.filter { $0.isNumber } }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("판매 정보") {
                    TextField("상품명", text: $clothingName)
                    HStack {
                        Text("가격").foregroundStyle(.secondary); Spacer()
                        TextField("0", text: formattedPriceBinding).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 130)
                        Text("원").foregroundStyle(.secondary).font(.subheadline)
                    }
                    TextField("판매 플랫폼", text: $platform)
                }
                Section("메모 (선택)") { TextField("메모", text: $note, axis: .vertical).lineLimit(3...) }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("판매 기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            let updated = CalendarEventEntity(
                                id: event.id, date: event.date,
                                type: .sale(SaleLogEntity(clothingID: log.clothingID, clothingName: clothingName, price: Double(price) ?? 0, platform: platform, note: note))
                            )
                            await viewModel.updateEvent(updated); dismiss()
                        }
                    }
                    .disabled(clothingName.isEmpty)
                }
            }
        }
    }
}

private struct CalendarEmptyStateView: View {
    let onAddOutfit: () -> Void
    let onAddPurchase: () -> Void
    let onAddSale: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Menu {
                Button { onAddOutfit() } label: { Label("착용 기록 ", systemImage: "tshirt") }
                Button { onAddPurchase() } label: { Label("구매 기록", systemImage: "cart") }
                Button { onAddSale() } label: { Label("판매 기록", systemImage: "tag") }
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
            }
            Text("기록 없음")
                .font(.headline)
            Text("이 날의 기록이 없습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CalendarEventRow: View {
    let event: CalendarEventEntity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.iconName)
                .font(.title2)
                .frame(width: 40)
                .foregroundStyle(event.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.title)
                    .font(.headline)
                Text(event.type.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension CalendarEventType {
    var iconName: String {
        switch self {
        case .outfit:   return "tshirt.fill"
        case .purchase: return "cart.fill"
        case .sale:     return "tag.fill"
        }
    }

    var title: String {
        switch self {
        case .outfit:           return "착용 기록"
        case .purchase(let l):  return "구매: \(l.clothingName)"
        case .sale(let l):      return "판매: \(l.clothingName)"
        }
    }

    var subtitle: String {
        switch self {
        case .outfit(let l):    return l.note.isEmpty ? "메모 없음" : l.note
        case .purchase(let l):  return "\(Int(l.price).formatted())원 · \(l.place)"
        case .sale(let l):      return "\(Int(l.price).formatted())원 · \(l.platform)"
        }
    }

    var color: Color {
        switch self {
        case .outfit:   return .purple
        case .purchase: return .blue
        case .sale:     return .green
        }
    }
}
