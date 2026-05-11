import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var showOutfitSheet = false
    @State private var showPurchaseSheet = false
    @State private var showSaleSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                        CalendarEmptyStateView()
                    } else {
                        List(viewModel.eventsForSelectedDate) { event in
                            CalendarEventRow(event: event)
                        }
                        .listStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("캘린더")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showOutfitSheet = true } label: {
                            Label("착용 기록", systemImage: "tshirt")
                        }
                        Button { showPurchaseSheet = true } label: {
                            Label("구매 기록", systemImage: "cart")
                        }
                        Button { showSaleSheet = true } label: {
                            Label("판매 기록", systemImage: "tag")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadEvents(for: viewModel.selectedDate)
                await viewModel.loadClothingList()
            }
            .sheet(isPresented: $showOutfitSheet) {
                OutfitRecordSheet()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showPurchaseSheet) {
                PurchaseRecordSheet()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showSaleSheet) {
                SaleRecordSheet()
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - 착용 기록 시트

struct OutfitRecordSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIDs: Set<UUID> = []
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("착용한 옷 선택") {
                    if viewModel.clothingList.isEmpty {
                        Text("등록된 옷이 없습니다.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.clothingList) { clothing in
                            Button {
                                if selectedIDs.contains(clothing.id) {
                                    selectedIDs.remove(clothing.id)
                                } else {
                                    selectedIDs.insert(clothing.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    // 썸네일
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
                                        Text(clothing.category.rawValue + (clothing.subCategory.isEmpty ? "" : " · \(clothing.subCategory)"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
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
                    }
                }
                Section("메모 (선택)") {
                    TextField("오늘의 코디 메모", text: $note, axis: .vertical)
                        .lineLimit(3...)
                }
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
                            await viewModel.recordOutfit(
                                clothingIDs: Array(selectedIDs),
                                note: note
                            )
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

private struct CalendarEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
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
