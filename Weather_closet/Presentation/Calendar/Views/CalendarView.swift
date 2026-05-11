import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel

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
                        Button("착용 기록") { }
                        Button("구매 기록") { }
                        Button("판매 기록") { }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await viewModel.loadEvents(for: viewModel.selectedDate) }
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
